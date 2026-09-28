import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> categories = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  // ==============================
  // LOAD KATEGORI
  // ==============================

  Future<void> loadCategories() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return;
      }

      final data = await supabase
          .from('categories')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        categories = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil kategori: $e'),
        ),
      );
    }
  }

  // ==============================
  // TAMBAH KATEGORI
  // ==============================

  Future<void> addCategory() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final nameController = TextEditingController();

    String selectedType = 'expense';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Tambah Kategori',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Kategori',
                      hintText: 'Contoh: Makanan',
                      prefixIcon: const Icon(
                        Icons.category_outlined,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Jenis',
                      prefixIcon: const Icon(
                        Icons.swap_vert,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'income',
                        child: Text('Pemasukan'),
                      ),
                      DropdownMenuItem(
                        value: 'expense',
                        child: Text('Pengeluaran'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedType = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Batal'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Nama kategori belum diisi',
                          ),
                        ),
                      );

                      return;
                    }

                    try {
                      await supabase.from('categories').insert({
                        'user_id': user.id,
                        'name': name,
                        'type': selectedType,
                        'icon': 'category',
                      });

                      if (!context.mounted) return;

                      Navigator.pop(context, true);
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gagal menambahkan kategori: $e',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();

    if (result == true) {
      loadCategories();
    }
  }

  // ==============================
  // HAPUS KATEGORI
  // ==============================

  Future<void> deleteCategory(
    String categoryId,
    String categoryName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Kategori?'),
          content: Text(
            'Apakah kategori "$categoryName" ingin dihapus?',
          ),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await supabase
          .from('categories')
          .delete()
          .eq('id', categoryId);

      loadCategories();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori berhasil dihapus'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus kategori: $e'),
        ),
      );
    }
  }

  // ==============================
  // ICON
  // ==============================

  IconData getCategoryIcon(String name) {
    final lowerName = name.toLowerCase();

    if (lowerName.contains('makan') ||
        lowerName.contains('minum') ||
        lowerName.contains('kuliner')) {
      return Icons.restaurant;
    }

    if (lowerName.contains('transport') ||
        lowerName.contains('bensin') ||
        lowerName.contains('kendaraan')) {
      return Icons.directions_car;
    }

    if (lowerName.contains('belanja') ||
        lowerName.contains('shopping')) {
      return Icons.shopping_cart;
    }

    if (lowerName.contains('tagihan') ||
        lowerName.contains('listrik') ||
        lowerName.contains('air')) {
      return Icons.receipt_long;
    }

    if (lowerName.contains('internet') ||
        lowerName.contains('wifi')) {
      return Icons.wifi;
    }

    if (lowerName.contains('pulsa') ||
        lowerName.contains('telepon')) {
      return Icons.phone_android;
    }

    if (lowerName.contains('pendidikan') ||
        lowerName.contains('sekolah') ||
        lowerName.contains('kuliah')) {
      return Icons.school;
    }

    if (lowerName.contains('kesehatan') ||
        lowerName.contains('obat') ||
        lowerName.contains('rumah sakit')) {
      return Icons.medical_services;
    }

    if (lowerName.contains('hiburan') ||
        lowerName.contains('game')) {
      return Icons.movie;
    }

    if (lowerName.contains('gaji')) {
      return Icons.work;
    }

    if (lowerName.contains('bonus')) {
      return Icons.card_giftcard;
    }

    if (lowerName.contains('penjualan') ||
        lowerName.contains('jualan')) {
      return Icons.store;
    }

    if (lowerName.contains('hadiah')) {
      return Icons.redeem;
    }

    return Icons.category;
  }

  // ==============================
  // BUILD
  // ==============================

  @override
  Widget build(BuildContext context) {
    final incomeCategories = categories
        .where((category) => category['type'] == 'income')
        .toList();

    final expenseCategories = categories
        .where((category) => category['type'] == 'expense')
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8B4C),
        foregroundColor: Colors.white,
        title: const Text(
          'Kategori',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F8B4C),
        foregroundColor: Colors.white,
        onPressed: addCategory,
        child: const Icon(Icons.add),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadCategories,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // ==========================
                  // PEMASUKAN
                  // ==========================

                  const Text(
                    'Pemasukan',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (incomeCategories.isEmpty)
                    _emptyCard(
                      'Belum ada kategori pemasukan',
                    )
                  else
                    ...incomeCategories.map(
                      (category) => _categoryCard(category),
                    ),

                  const SizedBox(height: 25),

                  // ==========================
                  // PENGELUARAN
                  // ==========================

                  const Text(
                    'Pengeluaran',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (expenseCategories.isEmpty)
                    _emptyCard(
                      'Belum ada kategori pengeluaran',
                    )
                  else
                    ...expenseCategories.map(
                      (category) => _categoryCard(category),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  // ==============================
  // CARD KATEGORI
  // ==============================

  Widget _categoryCard(
    Map<String, dynamic> category,
  ) {
    final bool isIncome = category['type'] == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),

        leading: CircleAvatar(
          backgroundColor: isIncome
              ? Colors.green.withValues(alpha: 0.12)
              : Colors.red.withValues(alpha: 0.12),
          child: Icon(
            getCategoryIcon(
              category['name'] ?? '',
            ),
            color: isIncome
                ? Colors.green
                : Colors.red,
          ),
        ),

        title: Text(
          category['name'] ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(
          isIncome
              ? 'Pemasukan'
              : 'Pengeluaran',
          style: TextStyle(
            color: isIncome
                ? Colors.green
                : Colors.red,
          ),
        ),

        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.red,
          ),
          onPressed: () {
            deleteCategory(
              category['id'],
              category['name'],
            );
          },
        ),
      ),
    );
  }

  // ==============================
  // EMPTY CARD
  // ==============================

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [

          const Icon(
            Icons.category_outlined,
            size: 42,
            color: Colors.grey,
          ),

          const SizedBox(height: 8),

          Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}