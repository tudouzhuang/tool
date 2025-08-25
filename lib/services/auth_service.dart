import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Store verification ID for phone auth
  String? _verificationId;
  int? _resendToken;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? get verificationId => _verificationId;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }
  Future<bool> verifyPassword(String password) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final storedPassword = data?['password'];
        if (storedPassword != null) {
          final hashedInputPassword = _hashPassword(password);
          return hashedInputPassword == storedPassword;
        }
      }
      return false;
    } catch (e) {
      print('Error verifying password: $e');
      return false;
    }
  }

// 1. Fix the verifyOTPForPasswordReset method
  Future<String?> verifyOTPForPasswordReset(String otp) async {
    try {
      if (_verificationId == null) {
        throw Exception('Verification ID not found. Please request OTP again.');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Sign in with the credential and keep the user signed in
      final userCredential = await _auth.signInWithCredential(credential);
      final phoneNumber = userCredential.user?.phoneNumber;
      final currentAuthUser = userCredential.user;

      // Find the user ID by phone number
      String? userId;
      if (phoneNumber != null) {
        userId = await findUserByPhoneNumber(phoneNumber);

        // If we found a user document, merge the accounts properly
        if (userId != null && currentAuthUser != null) {
          await _mergeAccountsAfterPhoneAuth(userId, currentAuthUser);
        }
      }

      // Return the userId (could be the original userId or current auth user's uid)
      return userId ?? currentAuthUser?.uid;
    } catch (e) {
      print('Error verifying OTP for password reset: $e');
      return null;
    }
  }

// 2. New method to properly merge accounts after phone authentication
  Future<void> _mergeAccountsAfterPhoneAuth(String originalUserId, User currentAuthUser) async {
    try {
      // Get the original user document
      final originalUserDoc = await _firestore.collection('users').doc(originalUserId).get();

      if (originalUserDoc.exists) {
        final originalData = originalUserDoc.data()!;

        // Update the current authenticated user's document with merged data
        await _firestore.collection('users').doc(currentAuthUser.uid).set({
          ...originalData, // Copy all original data
          'uid': currentAuthUser.uid, // Update with new auth uid
          'lastSignIn': DateTime.now().toIso8601String(),
          'phoneNumber': currentAuthUser.phoneNumber,
          'mergedFromAccount': originalUserId, // Track the merge
          'accountMergedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        // If the accounts are different, clean up the old document
        if (originalUserId != currentAuthUser.uid) {
          // Optionally: Keep a backup or delete the old document
          await _firestore.collection('users').doc(originalUserId).update({
            'accountMergedTo': currentAuthUser.uid,
            'mergedAt': DateTime.now().toIso8601String(),
          });
        }

        // Update the display name if it exists
        if (originalData['displayName'] != null) {
          await currentAuthUser.updateDisplayName(originalData['displayName']);
        }
      }
    } catch (e) {
      print('Error merging accounts after phone auth: $e');
    }
  }

// 3. Fix the resetPasswordForUser method to work with current authenticated user
  Future<bool> resetPasswordForUser(String userId, String newPassword) async {
    try {
      final hashedPassword = _hashPassword(newPassword);
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Always update the current authenticated user's document
      await _firestore.collection('users').doc(currentUser.uid).update({
        'password': hashedPassword,
        'passwordSetAt': DateTime.now().toIso8601String(),
        'hasPassword': true,
        'lastPasswordUpdate': DateTime.now().toIso8601String(),
      });

      // If the userId is different from current user uid, it means we had account merging
      if (userId != currentUser.uid) {
        // Also update the original document for consistency (optional)
        try {
          await _firestore.collection('users').doc(userId).update({
            'password': hashedPassword,
            'passwordSetAt': DateTime.now().toIso8601String(),
            'hasPassword': true,
            'lastPasswordUpdate': DateTime.now().toIso8601String(),
            'passwordResetForMergedAccount': currentUser.uid,
          });
        } catch (e) {
          print('Could not update original document (this is okay): $e');
        }
      }

      return true;
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

// 4. Add method to check if current user has password (most reliable)
  Future<bool> isPasswordSet() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['hasPassword'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking password status: $e');
      return false;
    }
  }

// 5. Add method to refresh user data after password operations
  Future<void> refreshCurrentUserData() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Force refresh the user data
        await user.reload();
        // You can also emit a stream event here if you have user data streams
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  // New method to sync user data after phone authentication
  Future<void> _syncUserDataAfterPhoneAuth(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;

        // Update last sign in time
        await _firestore.collection('users').doc(userId).update({
          'lastSignIn': DateTime.now().toIso8601String(),
        });

        // Link the phone number to the current Firebase Auth user if email exists
        final currentUser = _auth.currentUser;
        if (currentUser != null && userData['email'] != null) {
          try {
            // Update the display name if it exists in Firestore
            if (userData['displayName'] != null) {
              await currentUser.updateDisplayName(userData['displayName']);
            }
          } catch (e) {
            print('Error updating user profile: $e');
          }
        }
      }
    } catch (e) {
      print('Error syncing user data after phone auth: $e');
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? gender,
    String? dateOfBirth,
    String? avatarId,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);
      final updateData = <String, dynamic>{};

      if (displayName != null) updateData['displayName'] = displayName;
      if (gender != null) updateData['gender'] = gender;
      if (dateOfBirth != null) updateData['dateOfBirth'] = dateOfBirth;
      if (avatarId != null) updateData['avatarId'] = avatarId;

      await userDoc.update(updateData);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }











  // Add this method to your AuthService class

// Method to validate if current user exists in Firestore
  Future<bool> isCurrentUserValid() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists;
    } catch (e) {
      print('Error validating current user: $e');
      return false;
    }
  }

// Method to sign out user if they don't exist in Firestore
  Future<void> validateAndSignOutIfNeeded() async {
    try {
      final user = currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        // User document doesn't exist, sign them out
        await signOut();
        print('User signed out due to missing Firestore document');
      }
    } catch (e) {
      print('Error validating user and signing out: $e');
      // If there's an error accessing Firestore, sign out to be safe
      await signOut();
    }
  }

// Enhanced getUserData method that validates user existence
  Future<UserModel?> getUserDataWithValidation(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      } else {
        // User document doesn't exist, sign out the current user if it matches
        if (currentUser?.uid == uid) {
          await signOut();
        }
        return null;
      }
    } catch (e) {
      print('Error getting user data with validation: $e');
      // If there's an error, sign out to be safe
      if (currentUser?.uid == uid) {
        await signOut();
      }
      return null;
    }
  }












  // Phone Authentication Methods
  Future<bool> sendOTP(String phoneNumber, {bool isResend = false}) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on some devices
          print('Auto verification completed');
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          if (e.code == 'invalid-phone-number') {
            print('The provided phone number is not valid.');
          }
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          print('OTP sent to $phoneNumber');
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto retrieval timeout');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: isResend ? _resendToken : null,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  Future<bool> verifyOTP(String otp) async {
    try {
      if (_verificationId == null) {
        throw Exception('Verification ID not found. Please request OTP again.');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Verify the credential
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  // Find user by phone number for password reset
  Future<String?> findUserByPhoneNumber(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id; // Return user ID
      }
      return null;
    } catch (e) {
      print('Error finding user by phone number: $e');
      return null;
    }
  }

  // Phone number related methods
  Future<bool> savePhoneNumber(String phoneNumber) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'phoneNumber': phoneNumber,
        'phoneNumberAddedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error saving phone number: $e');
      return false;
    }
  }

  Future<bool> isPhoneNumberExists(String phoneNumber) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      for (var doc in querySnapshot.docs) {
        if (doc.id != user.uid) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking phone number existence: $e');
      return false;
    }
  }
// Add these methods to your AuthService class
















  Future<bool> hasPhoneNumber() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final phoneNumber = data?['phoneNumber'];
        return phoneNumber != null && phoneNumber.toString().isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking if user has phone number: $e');
      return false;
    }
  }

  Future<String?> getUserPhoneNumber() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['phoneNumber'];
      }
      return null;
    } catch (e) {
      print('Error getting user phone number: $e');
      return null;
    }
  }

  Future<bool> updatePhoneNumber(String newPhoneNumber) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final phoneExists = await isPhoneNumberExists(newPhoneNumber);
      if (phoneExists) {
        throw Exception('Phone number already exists with another account');
      }

      await _firestore.collection('users').doc(user.uid).update({
        'phoneNumber': newPhoneNumber,
        'phoneNumberUpdatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error updating phone number: $e');
      return false;
    }
  }

  // Hash password for security
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Save password to Firebase
  Future<bool> savePassword(String password) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final hashedPassword = _hashPassword(password);

      await _firestore.collection('users').doc(user.uid).update({
        'password': hashedPassword,
        'passwordSetAt': DateTime.now().toIso8601String(),
        'hasPassword': true,
      });

      return true;
    } catch (e) {
      print('Error saving password: $e');
      return false;
    }
  }
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final isOldPasswordValid = await verifyPassword(oldPassword);
      if (!isOldPasswordValid) {
        throw Exception('Current password is incorrect');
      }

      final hashedNewPassword = _hashPassword(newPassword);

      await _firestore.collection('users').doc(user.uid).update({
        'password': hashedNewPassword,
        'passwordSetAt': DateTime.now().toIso8601String(),
        'lastPasswordUpdate': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Clear verification data
  void clearVerificationData() {
    _verificationId = null;
    _resendToken = null;
  }

  // New method to check if user is currently authenticated
  bool get isUserAuthenticated => currentUser != null;

  // Method to refresh password status after reset
  Future<void> refreshPasswordStatus() async {
    // This method can be called after password reset to refresh the UI
    // The UI should listen to this and update accordingly
  }


  // Add this enhanced method to replace the existing _saveUserToFirestore
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      final now = DateTime.now();

      if (!docSnapshot.exists) {
        // New user - create with default values
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          createdAt: now,
          lastSignIn: now,
          gender: 'Not set',
          dateOfBirth: 'Not set',
          avatarId: '6',
          hasPassword: false,
          phoneNumber: user.phoneNumber, // Only set if Google provides it
        );

        await userDoc.set(userModel.toMap());
      } else {
        // Existing user - only update specific fields, preserve phone number
        final existingData = docSnapshot.data()!;
        final updateData = <String, dynamic>{
          'lastSignIn': now.toIso8601String(),
          'displayName': user.displayName ?? existingData['displayName'] ?? '',
        };

        // Only update phone number if it's provided by Google AND existing one is null/empty
        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          final existingPhone = existingData['phoneNumber'];
          if (existingPhone == null || existingPhone.toString().isEmpty) {
            updateData['phoneNumber'] = user.phoneNumber;
          }
        }

        await userDoc.update(updateData);
      }
    } catch (e) {
      print('Error saving user to Firestore: $e');
      rethrow;
    }
  }

// Method to find user by email address
  Future<UserModel?> findUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error finding user by email: $e');
      return null;
    }
  }

// Method to check if email already exists with phone number
  Future<bool> emailExistsWithPhoneNumber(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final phoneNumber = userData['phoneNumber'];
        return phoneNumber != null && phoneNumber.toString().isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking email with phone number: $e');
      return false;
    }
  }

// Enhanced method to merge Google user with existing Firestore data
  Future<UserModel?>


  mergeGoogleUserWithExistingData(User googleUser) async {
    try {
      if (googleUser.email == null) return null;

      // First check if there's an existing user with this email
      final existingUser = await findUserByEmail(googleUser.email!);

      if (existingUser != null) {
        // User exists, merge the accounts carefully preserving existing data
        final mergedData = {
          'uid': googleUser.uid, // Update with new auth uid
          'email': googleUser.email!, // Keep the email
          'displayName': googleUser.displayName ?? existingUser.displayName,
          'lastSignIn': DateTime.now().toIso8601String(),
          'mergedFromEmail': existingUser.email,
          'accountMergedAt': DateTime.now().toIso8601String(),
          // Preserve all existing data - don't overwrite with null values
          'phoneNumber': existingUser.phoneNumber, // Keep existing phone number
          'gender': existingUser.gender,
          'dateOfBirth': existingUser.dateOfBirth,
          'avatarId': existingUser.avatarId,
          'hasPassword': existingUser.hasPassword,
          'createdAt': existingUser.createdAt.toIso8601String(),
          'phoneNumberAddedAt': existingUser.toMap()['phoneNumberAddedAt'], // Preserve timestamp
        };

        // Only add non-null values to avoid overwriting existing data with null
        if (existingUser.toMap().containsKey('passwordSetAt')) {
          mergedData['passwordSetAt'] = existingUser.toMap()['passwordSetAt'];
        }
        if (existingUser.toMap().containsKey('password')) {
          mergedData['password'] = existingUser.toMap()['password'];
        }

        await _firestore.collection('users').doc(googleUser.uid).set(
            mergedData,
            SetOptions(merge: true)
        );

        // If the existing user had a different UID, mark the old document
        if (existingUser.uid != googleUser.uid) {
          try {
            await _firestore.collection('users').doc(existingUser.uid).update({
              'accountMergedTo': googleUser.uid,
              'mergedAt': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            print('Could not update old document: $e');
          }
        }

        // Return the merged user data with new UID
        return UserModel(
          uid: googleUser.uid,
          email: existingUser.email,
          displayName: googleUser.displayName ?? existingUser.displayName,
          createdAt: existingUser.createdAt,
          lastSignIn: DateTime.now(),
          gender: existingUser.gender,
          dateOfBirth: existingUser.dateOfBirth,
          avatarId: existingUser.avatarId,
          hasPassword: existingUser.hasPassword,
          phoneNumber: existingUser.phoneNumber, // Preserve existing phone number
        );
      } else {
        // No existing user, create new one
        await _saveUserToFirestore(googleUser);
        return await getUserData(googleUser.uid);
      }
    } catch (e) {
      print('Error merging Google user with existing data: $e');
      return null;
    }
  }









}