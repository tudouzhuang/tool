import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart'; // Add this import for .tr extension
import '../../provider/saved_cv_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/tools/tools_app_bar.dart';
import '../home_screen.dart';
import 'cv_maker_screen.dart';
import 'main_cv_screen.dart';

class CreateCvScreen extends StatefulWidget {
  const CreateCvScreen({super.key});

  @override
  State<CreateCvScreen> createState() => _CreateCvScreenState();
}

class _CreateCvScreenState extends State<CreateCvScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    try {
      final provider = Provider.of<SavedCVProvider>(context, listen: false);
      debugPrint('Initializing SavedCVProvider...');

      if (!provider.isInitialized) {
        await provider.initHive();
      } else {
        // If already initialized, just reload the data
        await provider.loadSavedCVs();
      }

      debugPrint('SavedCVProvider initialized successfully');
      debugPrint('Number of saved CVs: ${provider.savedCVs.length}');
    } catch (e) {
      debugPrint('Error initializing provider: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ToolsAppBar(
        title: 'my_resume'.tr,
        onBackPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SavedCVProvider>(
        builder: (context, savedCVProvider, child) {
          final savedCVs = savedCVProvider.savedCVs;

          // Debug print to see current state
          debugPrint(
              'Building CreateCvScreen with ${savedCVs.length} CVs');

          return RefreshIndicator(
            onRefresh: () async {
              await savedCVProvider.loadSavedCVs();
            },
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CvMakerScreen(),
                          ),
                        );
                      },
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.16),
                              blurRadius: 2,
                              offset: const Offset(0, 0),
                            )
                          ],
                          color: AppColors.bgBoxColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add,
                              color: AppColors.textColor,
                              size: 24,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'create_new'.tr,
                              style: GoogleFonts.inter(
                                color: AppColors.textColor,
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'previously_created_resume'.tr,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '(${savedCVs.length})',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: savedCVs.isEmpty
                                  ? Center(
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'no_saved_resumes_yet'.tr,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'create_first_resume_above'.tr,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: GridView.builder(
                                  gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 130 / 180,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: savedCVs.length,
                                  itemBuilder: (context, index) {
                                    final cv = savedCVs[index];
                                    return Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                        MainCVScreen(
                                                          templateId: cv
                                                              .templateId,
                                                          templateName:
                                                          '${'template'.tr} ${cv.templateId}',
                                                          editData: cv
                                                              .formData,
                                                          isEditing:
                                                          true,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 130,
                                                height: 190,
                                                decoration:
                                                BoxDecoration(
                                                  color: Colors
                                                      .grey[100],
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      8),
                                                  border: Border.all(
                                                      color: Colors
                                                          .grey[
                                                      300]!,
                                                      width: 1),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                      8),
                                                  child: cv.thumbnailBytes !=
                                                      null
                                                      ? Image
                                                      .memory(
                                                    cv.thumbnailBytes!,
                                                    fit: BoxFit
                                                        .cover,
                                                    errorBuilder: (context,
                                                        error,
                                                        stackTrace) {
                                                      return const Center(
                                                        child: Icon(
                                                            Icons.picture_as_pdf,
                                                            size: 40,
                                                            color: Colors.grey),
                                                      );
                                                    },
                                                  )
                                                      : const Center(
                                                    child: Icon(
                                                        Icons
                                                            .picture_as_pdf,
                                                        size:
                                                        40,
                                                        color:
                                                        Colors.grey),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                                height: 8),
                                            Padding(
                                              padding:
                                              const EdgeInsets
                                                  .symmetric(
                                                  horizontal:
                                                  4),
                                              child: Text(
                                                '${cv.dateTime} | ${cv.fileSize}',
                                                style: GoogleFonts
                                                    .inter(
                                                  fontSize: 8,
                                                  fontWeight:
                                                  FontWeight
                                                      .w400,
                                                  color: Colors
                                                      .grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                TextOverflow
                                                    .ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          right: 34,
                                          top: 10,
                                          child: GestureDetector(
                                            onTap: () async {
                                              final confirm =
                                              await showDialog<
                                                  bool>(
                                                context: context,
                                                builder:
                                                    (context) =>
                                                    AlertDialog(
                                                      title: Text(
                                                          'delete_resume'.tr,
                                                          style: GoogleFonts
                                                              .inter()),
                                                      content: Text(
                                                          'delete_resume_confirmation'.tr,
                                                          style: GoogleFonts
                                                              .inter()),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                  context)
                                                                  .pop(
                                                                  false),
                                                          child: Text(
                                                              'cancel'.tr,
                                                              style: GoogleFonts.inter(
                                                                  color:
                                                                  AppColors.primary)),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                  context)
                                                                  .pop(
                                                                  true),
                                                          child: Text(
                                                            'delete'.tr,
                                                            style: GoogleFonts.inter(
                                                                color: AppColors
                                                                    .primary),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );

                                              if (confirm == true) {
                                                savedCVProvider
                                                    .deleteSavedCV(
                                                    cv.id);
                                              }
                                            },
                                            child: Container(
                                              padding:
                                              const EdgeInsets
                                                  .all(4),
                                              decoration:
                                              BoxDecoration(
                                                color: Colors.white,
                                                shape:
                                                BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors
                                                        .black
                                                        .withOpacity(
                                                        0.2),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color:
                                                  Colors.red),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}