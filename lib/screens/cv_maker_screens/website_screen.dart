import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart'; // Add this import for .tr extension
import '../../models/website_model.dart';
import '../../provider/user_provider.dart';
import '../../widgets/tags_input_widget.dart';

class WebsitePage extends StatefulWidget {
  final List<Map<String, dynamic>>? initialData;

  const WebsitePage({
    this.initialData,
    super.key,
  });

  @override
  State<WebsitePage> createState() => _WebsitePageState();
}

class _WebsitePageState extends State<WebsitePage> {
  final TextEditingController _linkController = TextEditingController();
  final FocusNode _linkFocusNode = FocusNode();
  List<Website> links = [];
  bool _isInitialized = false;

  bool validate() {
    final provider = Provider.of<UserProvider>(context, listen: false);
    return provider.websites.isNotEmpty;
  }

  // Set maximum number of websites
  final int _maxWebsites = 2;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      setState(() {
        links = widget.initialData!.map((item) => Website.fromMap(item)).toList();
      });

      // Update provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<UserProvider>(context, listen: false)
            .updateWebsites(links);
      });
    } else {
      // Load from provider if no initial data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (userProvider.websites.isNotEmpty) {
          setState(() {
            links = List<Website>.from(userProvider.websites);
          });
        }
      });
    }
  }

  void _loadFromProvider() {
    if (!mounted) return;

    debugPrint('loading_from_provider'.tr);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    debugPrint(
        '${'provider_websites'.tr}: ${userProvider.websites.map((w) => '${w.name}: ${w.url}').toList()}');

    if (userProvider.websites.isNotEmpty && !_isInitialized) {
      debugPrint(
          '${'loading_websites_from_provider'.tr}: ${userProvider.websites.length}');
      setState(() {
        links = List<Website>.from(userProvider.websites);
        _isInitialized = true;
      });
      debugPrint('state_updated_with_provider_data'.tr);
    } else {
      debugPrint('provider_no_websites_or_initialized'.tr);
      setState(() {
        _isInitialized = true; // Mark as initialized even if empty
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('website_page_did_change_dependencies'.tr);

    // Only try to load from provider if we haven't initialized yet
    if (!_isInitialized) {
      _loadFromProvider();
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    _linkFocusNode.dispose();
    super.dispose();
  }

  void _addLink(String url) {
    debugPrint('${'adding_link'.tr}: $url');
    debugPrint('${'current_links_count'.tr}: ${links.length}, ${'max'.tr}: $_maxWebsites');

    if (links.length < _maxWebsites) {
      setState(() {
        links.add(Website(
          name: 'website'.tr,
          url: url,
        ));

        Provider.of<UserProvider>(context, listen: false).updateWebsites(links);
      });

      debugPrint('${'link_added_new_count'.tr}: ${links.length}');
      debugPrint(
          '${'updated_links'.tr}: ${links.map((w) => '${w.name}: ${w.url}').toList()}');
    } else {
      debugPrint('cannot_add_link_max_limit'.tr);
    }
  }

  void _removeLink(int index) {
    debugPrint('${'removing_link_at_index'.tr}: $index');
    debugPrint('${'link_to_remove'.tr}: ${links[index].url}');

    setState(() {
      links.removeAt(index);
      Provider.of<UserProvider>(context, listen: false).updateWebsites(links);
    });

    debugPrint('${'link_removed_new_count'.tr}: ${links.length}');
    debugPrint(
        '${'remaining_links'.tr}: ${links.map((w) => '${w.name}: ${w.url}').toList()}');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.initialData != null &&
                      widget.initialData!.isNotEmpty)
                    Text(
                      'previously_saved_links'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  TagInputWidget<Website>(
                    title: 'add_your_links'.tr,
                    inputLabel: 'link'.tr,
                    hintText: 'enter_url'.tr,
                    items: links,
                    getItemName: (website) => website.url,
                    onAdd: _addLink,
                    onRemove: _removeLink,
                    emptyMessage: 'no_links_added_yet'.tr,
                    controller: _linkController,
                    focusNode: _linkFocusNode,
                    maxItems: _maxWebsites,
                    minItemsRequired: 1, // Add this parameter
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}