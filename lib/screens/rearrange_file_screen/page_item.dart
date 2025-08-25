class PageItem {
  final int originalIndex;
  int? userDefinedPosition;
  bool isSelected;
  final int pageNumber;

  PageItem({
    required this.originalIndex,
    required this.userDefinedPosition,
    required this.isSelected,
    required this.pageNumber,
  });
}
