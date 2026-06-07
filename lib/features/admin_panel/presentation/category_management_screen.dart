import 'package:flutter/material.dart';

import '../data/admin_repository.dart';
import '../domain/models/category_item.dart';

const _navy = Color(0xFF0F1E36);
const _primary = Color(0xFF2E5BFF);

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final AdminRepository _repository = AdminRepository();

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            hintText: 'mis. JALAN, DRAINASE',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      try {
        await _repository.addCategory(name);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menambah kategori: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(CategoryItem category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kategori?'),
        content: Text('Kategori "${category.name}" akan dihapus dari katalog.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Color(0xFFD32F2F)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteCategory(category.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus kategori: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleActive(CategoryItem category, bool isActive) async {
    try {
      await _repository.setCategoryActive(
        categoryId: category.id,
        isActive: isActive,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui kategori: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<CategoryItem>>(
        stream: _repository.watchCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat kategori: ${snapshot.error}'),
            );
          }

          final categories = snapshot.data ?? const [];
          if (categories.isEmpty) {
            return const Center(
              child: Text('Belum ada kategori. Tambahkan lewat tombol +.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _navy,
                    ),
                  ),
                  subtitle: Text(category.isActive ? 'Aktif' : 'Nonaktif'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: category.isActive,
                        activeThumbColor: _primary,
                        onChanged: (val) => _toggleActive(category, val),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFD32F2F),
                        ),
                        onPressed: () => _confirmDelete(category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
