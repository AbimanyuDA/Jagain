import 'package:flutter/material.dart';

/// Bottom sheet yang bisa di-search untuk memilih item dari sebuah list.
/// Digunakan untuk memilih provinsi, kota, atau kecamatan.
Future<String?> showRegionSelectorSheet({
  required BuildContext context,
  required String title,
  required List<String> items,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RegionSelectorSheet(
      title: title,
      items: items,
      selected: selected,
    ),
  );
}

class _RegionSelectorSheet extends StatefulWidget {
  const _RegionSelectorSheet({
    required this.title,
    required this.items,
    this.selected,
  });

  final String title;
  final List<String> items;
  final String? selected;

  @override
  State<_RegionSelectorSheet> createState() => _RegionSelectorSheetState();
}

class _RegionSelectorSheetState extends State<_RegionSelectorSheet> {
  final _searchController = TextEditingController();
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchController.addListener(() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filtered = widget.items
            .where((item) => item.toLowerCase().contains(query))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3564),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari ${widget.title.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ditemukan',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = _filtered[i];
                      final isSelected = item == widget.selected;
                      return ListTile(
                        title: Text(
                          item,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF1B3564)
                                : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check,
                                color: Color(0xFF1B3564))
                            : null,
                        onTap: () => Navigator.of(ctx).pop(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
