import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toolkit/screens/convert_word_screen/convert_word_main_screen.dart';
import '../screens/convert_image_screens/convert_img_main_screen.dart';
import '../screens/convert_pdf_screens/convert_pdf_main_screen.dart';
import 'tool_item.dart';

class ConvertOptionsView extends StatelessWidget {
  const ConvertOptionsView({super.key});

  final List<Map<String, String>> convertOptions = const [
    {
      'icon': 'assets/icons/convert_pdf.svg',
      'id': 'convert_pdf',
    },
    {
      'icon': 'assets/icons/convert_img_icon.svg',
      'id': 'convert_image',
    },
    {
      'icon': 'assets/icons/word_icon.svg',
      'id':'convert_word',
    },
  ];

  void _navigateToConvertPage(BuildContext context, String convertId) {
    switch (convertId) {
      case 'convert_pdf':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ConvertPdfMainScreen(),
          ),
        );
        break;
      case 'convert_image':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ConvertImgMainScreen(),
          ),
        );
        break;
      case 'convert_word':
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConvertWordToPdfMainScreen(),
            )
        );
      default:
      // Handle unknown conversion option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('conversion_not_implemented'.trParams({'conversion': convertId}))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: convertOptions.length,
        itemBuilder: (context, index) {
          final option = convertOptions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ToolItem(
              icon: option['icon']!,
              name: option['id']!.tr, // Use id field with .tr for translation
              onTap: () {
                _navigateToConvertPage(context, option['id']!);
              },
            ),
          );
        },
      ),
    );
  }
}