import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class TagInputWidget<T> extends StatefulWidget {
  final String title;
  final String inputLabel;
  final String hintText;
  final List<T> items;
  final String Function(T) getItemName;
  final void Function(String) onAdd;
  final void Function(int) onRemove;
  final String emptyMessage;
  final TextEditingController controller;
  final FocusNode focusNode;
  final int maxItems; // Add maxItems parameter
  final int minItemsRequired;

  const TagInputWidget({
    super.key,
    required this.title,
    required this.inputLabel,
    required this.hintText,
    required this.items,
    required this.getItemName,
    required this.onAdd,
    required this.onRemove,
    required this.emptyMessage,
    required this.controller,
    required this.focusNode,
    required this.minItemsRequired,
    this.maxItems = 6, // Default max items to 6 for backward compatibility
  });

  @override
  State<TagInputWidget<T>> createState() => _TagInputWidgetState<T>();
}

class _TagInputWidgetState<T> extends State<TagInputWidget<T>> {
  void _addItem() {
    if (widget.controller.text.trim().isNotEmpty &&
        widget.items.length < widget.maxItems) {
      widget.onAdd(widget.controller.text.trim());
      widget.controller.clear();
      widget.focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInputForm(),
        const SizedBox(height: 30),
        _buildItemsList(),
      ],
    );
  }

  Widget _buildInputForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.30),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    bool canAddMore =
        widget.items.length < widget.maxItems; // Use maxItems parameter

    return Focus(
      onKey: (FocusNode node, RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            canAddMore) {
          _addItem();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.inputLabel,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.30),
                        blurRadius: 2,
                        offset: const Offset(0, 0),
                      ),
                    ],
                    color: AppColors.bgBoxColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: AppColors.primary,
                        selectionColor: AppColors.primary.withOpacity(0.3),
                        selectionHandleColor: AppColors.primary,
                      ),
                    ),
                    child: TextFormField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      cursorColor: AppColors.primary,
                      enabled: canAddMore,
                      decoration: InputDecoration(
                        hintText: canAddMore
                            ? widget.hintText
                            : 'Maximum ${widget.inputLabel.toLowerCase()}s reached',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: canAddMore ? _addItem : null,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: canAddMore
                        ? const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey[300]!,
                              Colors.grey[400]!,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add,
                    color: canAddMore ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.30),
            blurRadius: 2,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your ${widget.inputLabel}s',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            widget.items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        widget.emptyMessage,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      widget.items.length,
                      (index) => _buildTag(widget.items[index], index),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(T item, int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Tag Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.getItemName(item),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ),

        Positioned(
          top: -6,
          right: -4,
          child: GestureDetector(
            onTap: () => widget.onRemove(index),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.close,
                  color: AppColors.primary,
                  size: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
