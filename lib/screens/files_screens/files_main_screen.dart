import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart'; // GetX ke liye import karna zaroori hai
import '../../models/file_model.dart';
import '../../utils/app_colors.dart';
import '../../widgets/settings_widgets/all_files_tab.dart';
import '../../widgets/settings_widgets/favorites_view_tab.dart';
import '../../widgets/settings_widgets/recent_view_tab.dart';

class FilesMainScreen extends StatefulWidget {
  final bool isSelectingFiles;
  const FilesMainScreen({super.key, this.isSelectingFiles = false});

  @override
  State<FilesMainScreen> createState() => _FilesMainScreenState();
}

class _FilesMainScreenState extends State<FilesMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  void _onFileSelected(FileModel file, int index) {
    if (widget.isSelectingFiles) {
      // Check file size
      final sizeParts = file.size.split(' ');
      if (sizeParts.length == 2) {
        final sizeValue = double.tryParse(sizeParts[0]) ?? 0;
        final sizeUnit = sizeParts[1].toUpperCase();

        double sizeInMB = sizeValue;
        if (sizeUnit == 'KB') {
          sizeInMB = sizeValue / 1024;
        } else if (sizeUnit == 'GB') {
          sizeInMB = sizeValue * 1024;
        }

        if (sizeInMB > 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('file_size_limit_error'.tr), // Localized text
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Return only the selected file
      Navigator.of(context).pop([file]);
    } else {
      // Normal file handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  if (_isSearching) const SizedBox(width: 8),
                  Expanded(
                    child: _isSearching
                        ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'search_files_hint'.tr, // Localized hint text
                        hintStyle: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    )
                        : Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          'files_title'.tr, // Localized title
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isSearching ? Icons.close : Icons.search,
                      color: Colors.black,
                      size: 24,
                    ),
                    onPressed: _toggleSearch,
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 2.0,
                  color: AppColors.primary,
                ),
                insets: EdgeInsets.only(left: 20, right: 20, bottom: 8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              splashFactory: InkRipple.splashFactory,
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                  if (states.contains(WidgetState.pressed)) {
                    return AppColors.primary.withOpacity(0.12);
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return AppColors.primary.withOpacity(0.08);
                  }
                  if (states.contains(WidgetState.focused)) {
                    return AppColors.primary.withOpacity(0.08);
                  }
                  return null;
                },
              ),
              tabs: [
                Tab(text: 'recents_tab'.tr), // Localized tab text
                Tab(text: 'favourites_tab'.tr), // Localized tab text
                Tab(text: 'all_tab'.tr), // Localized tab text
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: RecentsViewTab(
                        searchQuery: _searchController.text,
                        onFileSelected: _onFileSelected,
                        isSelectingFiles: widget.isSelectingFiles,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FavoritesView(
                        searchQuery: _searchController.text,
                        onFileSelected: _onFileSelected,
                        isSelectingFiles: widget.isSelectingFiles,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AllFilesView(
                        searchQuery: _searchController.text,
                        onFileSelected: _onFileSelected,
                        isSelectingFiles: widget.isSelectingFiles,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}