import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> categories = [];

  bool isLoading = true;

  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> loadAllData() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final accountResult = await supabase
          .from('accounts')
          .select()
          .eq('user_id', user.id)
          .order('name');

      final categoryResult = await supabase
          .from('categories')
          .select()
          .eq('user_id', user.id)
          .order('name');

      final transactionResult = await supabase
          .from('transactions')
          .select('''
            *,
            accounts (
              name,
              provider
            ),
            categories (
              name,
              type
            )
          ''')
          .eq('user_id', user.id)
          .order(
            'transaction_date',
            ascending: false,
          )
          .order(
            'created_at',
            ascending: false,
          );

      if (!mounted) return;

      setState(() {
        accounts =
            List<Map<String, dynamic>>.from(accountResult);

        categories =
            List<Map<String, dynamic>>.from(categoryResult);

        transactions =
            List<Map<String, dynamic>>.from(
          transactionResult,
        );

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Gagal mengambil data: $e',
      );
    }
  }

  // ============================================================
  // TAMBAH TRANSAKSI
  // ============================================================

  Future<void> showAddTransaction() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('Silakan login terlebih dahulu.');
      return;
    }

    if (accounts.isEmpty) {
      showMessage(
        'Belum ada rekening. Tambahkan rekening terlebih dahulu.',
      );
      return;
    }

    if (categories.isEmpty) {
      showMessage(
        'Belum ada kategori. Tambahkan kategori terlebih dahulu.',
      );
      return;
    }

    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    String transactionType = 'expense';

    String selectedAccountId =
        accounts.first['id'].toString();

    List<Map<String, dynamic>> availableCategories =
        categories
            .where(
              (item) =>
                  item['type'] == transactionType,
            )
            .toList();

    String? selectedCategoryId;

    if (availableCategories.isNotEmpty) {
      selectedCategoryId =
          availableCategories.first['id'].toString();
    }

    DateTime transactionDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Tambah Transaksi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // JENIS
                      DropdownButtonFormField<String>(
                        initialValue: transactionType,
                        decoration: InputDecoration(
                          labelText: 'Jenis Transaksi',
                          prefixIcon: const Icon(
                            Icons.swap_vert,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'income',
                            child: Text(
                              'Pemasukan',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'expense',
                            child: Text(
                              'Pengeluaran',
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            transactionType = value;

                            availableCategories =
                                categories
                                    .where(
                                      (item) =>
                                          item['type'] ==
                                          transactionType,
                                    )
                                    .toList();

                            if (availableCategories
                                .isNotEmpty) {
                              selectedCategoryId =
                                  availableCategories
                                      .first['id']
                                      .toString();
                            } else {
                              selectedCategoryId = null;
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      // KATEGORI
                      DropdownButtonFormField<String>(
                        initialValue:
                            selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        items: availableCategories
                            .map(
                              (category) {
                                return DropdownMenuItem<
                                    String>(
                                  value:
                                      category['id']
                                          .toString(),
                                  child: Text(
                                    category['name']
                                        .toString(),
                                  ),
                                );
                              },
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCategoryId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      // REKENING
                      DropdownButtonFormField<String>(
                        initialValue:
                            selectedAccountId,
                        decoration: InputDecoration(
                          labelText: 'Rekening',
                          prefixIcon: const Icon(
                            Icons.account_balance_wallet,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                        items: accounts.map(
                          (account) {
                            return DropdownMenuItem<String>(
                              value:
                                  account['id'].toString(),
                              child: Text(
                                '${account['name']} - ${account['provider']}',
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedAccountId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      // NOMINAL
                      TextField(
                        controller: amountController,
                        keyboardType:
                            TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Nominal',
                          hintText: 'Contoh: 50000',
                          prefixText: 'Rp ',
                          prefixIcon: const Icon(
                            Icons.payments_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // TANGGAL
                      InkWell(
                        onTap: () async {
                          final picked =
                              await showDatePicker(
                            context: context,
                            initialDate:
                                transactionDate,
                            firstDate:
                                DateTime(2020),
                            lastDate:
                                DateTime(2100),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              transactionDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tanggal',
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            formatDate(
                              transactionDate,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // KETERANGAN
                      TextField(
                        controller:
                            descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Keterangan',
                          hintText:
                              'Contoh: Makan malam',
                          prefixIcon: const Icon(
                            Icons.notes,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text('Batal'),
                ),

                ElevatedButton.icon(
                  icon: const Icon(
                    Icons.save,
                  ),
                  label: const Text(
                    'Simpan',
                  ),
                  onPressed: () async {
                    final amountText =
                        amountController.text.trim();

                    if (amountText.isEmpty) {
                      showMessage(
                        'Nominal belum diisi.',
                      );
                      return;
                    }

                    final amount = double.tryParse(
                      amountText
                          .replaceAll('.', '')
                          .replaceAll(',', ''),
                    );

                    if (amount == null ||
                        amount <= 0) {
                      showMessage(
                        'Nominal tidak valid.',
                      );
                      return;
                    }

                    if (selectedCategoryId == null) {
                      showMessage(
                        'Kategori belum tersedia untuk jenis transaksi ini.',
                      );
                      return;
                    }

                    try {
                      await supabase
                          .from('transactions')
                          .insert({
                        'user_id': user.id,
                        'account_id':
                            selectedAccountId,
                        'category_id':
                            selectedCategoryId,
                        'type':
                            transactionType,
                        'amount': amount,
                        'description':
                            descriptionController.text
                                .trim(),
                        'transaction_date':
                            formatDatabaseDate(
                          transactionDate,
                        ),
                      });

                      if (!dialogContext.mounted) {
                        return;
                      }

                      Navigator.pop(
                        dialogContext,
                        true,
                      );
                    } catch (e) {
                      if (!dialogContext.mounted) {
                        return;
                      }

                      showMessage(
                        'Gagal menyimpan transaksi: $e',
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    descriptionController.dispose();

    if (result == true) {
      await loadAllData();

      if (mounted) {
        showMessage(
          'Transaksi berhasil disimpan.',
        );
      }
    }
  }

  // ============================================================
  // HAPUS TRANSAKSI
  // ============================================================

  Future<void> deleteTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Transaksi?',
          ),
          content: const Text(
            'Data transaksi yang dihapus tidak dapat dikembalikan.',
          ),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Batal',
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Hapus',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await supabase
          .from('transactions')
          .delete()
          .eq(
            'id',
            transaction['id'].toString(),
          );

      await loadAllData();

      if (mounted) {
        showMessage(
          'Transaksi berhasil dihapus.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          'Gagal menghapus transaksi: $e',
        );
      }
    }
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String formatRupiah(dynamic value) {
    final number =
        double.tryParse(value.toString()) ?? 0;

    final rounded = number.round();

    final text = rounded.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 &&
          (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return 'Rp ${buffer.toString()}';
  }

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatDatabaseDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // FILTER TRANSAKSI
  // ============================================================

  List<Map<String, dynamic>> get filteredTransactions {
    if (selectedFilter == 'all') {
      return transactions;
    }

    return transactions
        .where(
          (transaction) =>
              transaction['type'] ==
              selectedFilter,
        )
        .toList();
  }

  // ============================================================
  // TOTAL PEMASUKAN
  // ============================================================

  double get totalIncome {
    double total = 0;

    for (final transaction in transactions) {
      if (transaction['type'] == 'income') {
        total +=
            double.tryParse(
                  transaction['amount'].toString(),
                ) ??
                0;
      }
    }

    return total;
  }

  // ============================================================
  // TOTAL PENGELUARAN
  // ============================================================

  double get totalExpense {
    double total = 0;

    for (final transaction in transactions) {
      if (transaction['type'] == 'expense') {
        total +=
            double.tryParse(
                  transaction['amount'].toString(),
                ) ??
                0;
      }
    }

    return total;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final visibleTransactions =
        filteredTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8B4C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor:
            const Color(0xFF0F8B4C),
        foregroundColor: Colors.white,
        onPressed: showAddTransaction,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Tambah',
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadAllData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // ==================================================
                  // RINGKASAN
                  // ==================================================

                  Row(
                    children: [

                      Expanded(
                        child: summaryCard(
                          title: 'Pemasukan',
                          amount:
                              formatRupiah(
                            totalIncome,
                          ),
                          icon:
                              Icons.arrow_downward,
                          color:
                              Colors.green,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: summaryCard(
                          title: 'Pengeluaran',
                          amount:
                              formatRupiah(
                            totalExpense,
                          ),
                          icon:
                              Icons.arrow_upward,
                          color:
                              Colors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // FILTER
                  // ==================================================

                  const Text(
                    'Filter Transaksi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection:
                        Axis.horizontal,
                    child: Row(
                      children: [

                        filterButton(
                          label: 'Semua',
                          value: 'all',
                        ),

                        const SizedBox(width: 8),

                        filterButton(
                          label: 'Pemasukan',
                          value: 'income',
                        ),

                        const SizedBox(width: 8),

                        filterButton(
                          label: 'Pengeluaran',
                          value: 'expense',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // JUDUL
                  // ==================================================

                  const Text(
                    'Daftar Transaksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // KOSONG
                  // ==================================================

                  if (visibleTransactions.isEmpty)
                    Container(
                      padding:
                          const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: const Column(
                        children: [

                          Icon(
                            Icons
                                .receipt_long_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),

                          SizedBox(height: 12),

                          Text(
                            'Belum ada transaksi',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Tekan tombol Tambah untuk membuat transaksi.',
                            textAlign:
                                TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ==================================================
                  // LIST TRANSAKSI
                  // ==================================================

                  ...visibleTransactions.map(
                    (transaction) {
                      return transactionCard(
                        transaction,
                      );
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget summaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          CircleAvatar(
            radius: 18,
            backgroundColor:
                color.withValues(
              alpha: 0.12,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER BUTTON
  // ============================================================

  Widget filterButton({
    required String label,
    required String value,
  }) {
    final bool active =
        selectedFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        setState(() {
          selectedFilter = value;
        });
      },
      selectedColor:
          const Color(0xFF0F8B4C),
      labelStyle: TextStyle(
        color: active
            ? Colors.white
            : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ============================================================
  // TRANSACTION CARD
  // ============================================================

  Widget transactionCard(
    Map<String, dynamic> transaction,
  ) {
    final bool isIncome =
        transaction['type'] == 'income';

    final category =
        transaction['categories']
            as Map<String, dynamic>?;

    final account =
        transaction['accounts']
            as Map<String, dynamic>?;

    final categoryName =
        category?['name'] ?? 'Kategori';

    final accountName =
        account?['name'] ?? 'Rekening';

    final provider =
        account?['provider'] ?? '';

    final description =
        transaction['description'] ?? '';

    final date =
        transaction['transaction_date'] ?? '';

    final amount =
        transaction['amount'];

    return Container(
      margin:
          const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),

        leading: CircleAvatar(
          backgroundColor:
              isIncome
                  ? Colors.green.withValues(
                      alpha: 0.12,
                    )
                  : Colors.red.withValues(
                      alpha: 0.12,
                    ),
          child: Icon(
            isIncome
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isIncome
                ? Colors.green
                : Colors.red,
          ),
        ),

        title: Text(
          categoryName.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                '$accountName'
                '${provider.toString().isNotEmpty ? ' • $provider' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),

              if (description
                  .toString()
                  .isNotEmpty)
                Text(
                  description.toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

              const SizedBox(height: 3),

              Text(
                date.toString(),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        trailing: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [

            Text(
              '${isIncome ? '+' : '-'} ${formatRupiah(amount)}',
              style: TextStyle(
                color: isIncome
                    ? Colors.green
                    : Colors.red,
                fontWeight:
                    FontWeight.bold,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 5),

            InkWell(
              onTap: () {
                deleteTransaction(
                  transaction,
                );
              },
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 21,
              ),
            ),
          ],
        ),
      ),
    );
  }
}