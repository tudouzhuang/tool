import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toolkit/screens/file_transfer_screen/file_transfer_screen.dart';
import 'package:toolkit/screens/rearrange_file_screen/rearrange_file_screen.dart';
import '../screens/compress_files_screen/compress_file_screen.dart';
import '../screens/edit_files_screen/edit_file_screen.dart';
import '../screens/merge_files_screens/merge_file_main_screen.dart';
import '../screens/ocr_screens/ocr_screen.dart';
import '../screens/split_screen/split_screen.dart';
import 'tool_item.dart';

class ToolsListView extends StatefulWidget {
  const ToolsListView({super.key});

  @override
  State createState() => _ToolsListViewState();
}

class _ToolsListViewState extends State<ToolsListView> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _itemsPerPage = 4;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final double offset = _scrollController.offset;
      final double maxScrollExtent = _scrollController.position.maxScrollExtent;

      // Calculate which page we're on based on scroll position
      final int page = (offset /
              maxScrollExtent *
              ((tools.length / _itemsPerPage).ceil() - 1))
          .round();

      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    }
  }

  // Navigate to the appropriate page based on tool id
  void _navigateToToolPage(BuildContext context, String toolId) {
    switch (toolId) {
      case 'ocr':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const OcrScreen(),
        ));
        break;
      case 'compress_files':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const CompressFileScreen(),
        ));
        break;
      case 'merge_files':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const MergeFileMainScreen(),
        ));
        break;
      case 'edit_file':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const EditFileScreen(),
        ));
        break;
      case 'split_file':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const SplitScreen(),
        ));
        break;
      case 'rearrange_file':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const RearrangeFileScreen(),
        ));
        break;
      case 'file_transfer':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const FileTransferScreen(),
        ));
        break;
      default:
        // Handle unknown tool
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('tool_not_implemented'.trParams({'tool': toolId}))),
        );
    }
  }

  final List<Map<String, String>> tools = [
    {
      'icon': 'assets/icons/ocr_icon.svg',
      'name_key': 'ocr_tool',
      'id': 'ocr',
    },
    {
      'icon': 'assets/icons/compress_file_icon.svg',
      'name_key': 'compress_files_tool',
      'id': 'compress_files',
    },
    {
      'icon': 'assets/icons/merge_file_icon.svg',
      'name_key': 'merge_files_tool',
      'id': 'merge_files',
    },
    {
      'icon': 'assets/icons/edit_file_icon.svg',
      'name_key': 'edit_file_tool',
      'id': 'edit_file',
    },
    {
      'icon': 'assets/icons/split_file_icon.svg',
      'name_key': 'split_file_tool',
      'id': 'split_file',
    },
    {
      'icon': 'assets/icons/rearrange_file_icon.svg',
      'name_key': 'rearrange_file_tool',
      'id': 'rearrange_file',
    },
    {
      'icon': 'assets/icons/file_transfer_icon.svg',
      'name_key': 'file_transfer_tool',
      'id': 'file_transfer',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final int pagesCount = (tools.length / _itemsPerPage).ceil();

    return Column(
      children: [
        // Fixed height container for the horizontal list
        SizedBox(
          height: 130,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: tools.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ToolItem(
                  icon: tools[index]['icon']!,
                  name: tools[index]['id']!.tr,
                  // Use id field with .tr for translation
                  onTap: () {
                    // Navigate to the appropriate tool page using the 'id' field
                    _navigateToToolPage(context, tools[index]['id']!);
                  },
                ),
              );
            },
          ),
        ),

        // Pagination dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            pagesCount,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Colors.black
                      : Colors.grey.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}


