import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // =========================================================
  // LOAD DATA
  // =========================================================

  Future<void> loadAllData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User belum login.');
      }

      final accountsResponse = await supabase
          .from('accounts')
          .select()
          .eq('user_id', user.id)
          .order('name');

      final categoriesResponse = await supabase
          .from('categories')
          .select()
          .eq('user_id', user.id)
          .order('name');

      final transactionsResponse = await supabase
          .from('transactions')
          .select('''
            *,
            accounts (
              id,
              name,
              provider,
              type
            ),
            categories (
              id,
              name,
              type,
              icon
            )
          ''')
          .eq('user_id', user.id)
          .order('transaction_date', ascending: false)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        accounts = List<Map<String, dynamic>>.from(
          accountsResponse.map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );

        categories = List<Map<String, dynamic>>.from(
          categoriesResponse.map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );

        transactions = List<Map<String, dynamic>>.from(
          transactionsResponse.map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Gagal memuat transaksi: $e',
        isError: true,
      );
    }
  }

  // =========================================================
  // ADD TRANSACTION
  // =========================================================

  Future<void> showAddTransactionDialog() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage(
        'User belum login.',
        isError: true,
      );
      return;
    }

    if (accounts.isEmpty) {
      showMessage(
        'Tambahkan rekening terlebih dahulu.',
        isError: true,
      );
      return;
    }

    if (categories.isEmpty) {
      showMessage(
        'Tambahkan kategori terlebih dahulu.',
        isError: true,
      );
      return;
    }

    String selectedType = 'expense';

    // Gunakan dynamic supaya ID bisa int maupun String.
    dynamic selectedAccountId = accounts.first['id'];

    DateTime selectedDate = DateTime.now();

    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    dynamic selectedCategoryId;

    List<Map<String, dynamic>> filteredCategories =
        categories.where((category) {
      return category['type'] == selectedType;
    }).toList();

    if (filteredCategories.isNotEmpty) {
      selectedCategoryId = filteredCategories.first['id'];
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            filteredCategories = categories.where((category) {
              return category['type'] == selectedType;
            }).toList();

            if (filteredCategories.isEmpty) {
              selectedCategoryId = null;
            } else {
              final exists = filteredCategories.any(
                (category) => category['id'] == selectedCategoryId,
              );

              if (!exists) {
                selectedCategoryId = filteredCategories.first['id'];
              }
            }

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
                      // =================================================
                      // JENIS TRANSAKSI
                      // =================================================

                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Transaksi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.swap_vert),
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
                          if (value == null) return;

                          setDialogState(() {
                            selectedType = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // =================================================
                      // REKENING
                      // =================================================

                      DropdownButtonFormField<dynamic>(
                        value: selectedAccountId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Rekening',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                        items: accounts.map((account) {
                          final accountId = account['id'];

                          final name =
                              account['name']?.toString() ?? 'Rekening';

                          final provider =
                              account['provider']?.toString() ?? '';

                          return DropdownMenuItem<dynamic>(
                            value: accountId,
                            child: Text(
                              provider.isEmpty
                                  ? name
                                  : '$name - $provider',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedAccountId = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // =================================================
                      // KATEGORI
                      // =================================================

                      DropdownButtonFormField<dynamic>(
                        value: selectedCategoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: filteredCategories.map((category) {
                          final categoryId = category['id'];

                          final name =
                              category['name']?.toString() ?? 'Kategori';

                          return DropdownMenuItem<dynamic>(
                            value: categoryId,
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: filteredCategories.isEmpty
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedCategoryId = value;
                                });
                              },
                      ),

                      if (filteredCategories.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Belum ada kategori untuk jenis transaksi ini.',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // =================================================
                      // NOMINAL
                      // =================================================

                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nominal',
                          hintText: 'Contoh: 50000',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payments),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =================================================
                      // TANGGAL
                      // =================================================

                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_month),
                          ),
                          child: Text(
                            DateFormat(
                              'dd MMMM yyyy',
                              'id_ID',
                            ).format(selectedDate),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =================================================
                      // KETERANGAN
                      // =================================================

                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan',
                          hintText: 'Contoh: Gaji bulan September',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () async {
                    await addTransaction(
                      dialogContext: dialogContext,
                      userId: user.id,
                      accountId: selectedAccountId,
                      categoryId: selectedCategoryId,
                      type: selectedType,
                      amountText: amountController.text,
                      description: descriptionController.text,
                      date: selectedDate,
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    amountController.dispose();
    descriptionController.dispose();
  }

  // =========================================================
  // INSERT TRANSACTION
  // =========================================================

  Future<void> addTransaction({
    required BuildContext dialogContext,
    required String userId,
    required dynamic accountId,
    required dynamic categoryId,
    required String type,
    required String amountText,
    required String description,
    required DateTime date,
  }) async {
    if (accountId == null) {
      showMessage(
        'Pilih rekening terlebih dahulu.',
        isError: true,
      );
      return;
    }

    if (categoryId == null) {
      showMessage(
        'Pilih kategori terlebih dahulu.',
        isError: true,
      );
      return;
    }

    final amount = parseAmount(amountText);

    if (amount <= 0) {
      showMessage(
        'Nominal harus lebih dari 0.',
        isError: true,
      );
      return;
    }

    try {
      await supabase.from('transactions').insert({
        'user_id': userId,
        'account_id': accountId,
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'description': description.trim().isEmpty
            ? null
            : description.trim(),
        'transaction_date': dbDate(date),
      });

      if (!mounted) return;

      Navigator.pop(dialogContext);

      await loadAllData();

      if (!mounted) return;

      showMessage(
        'Transaksi berhasil ditambahkan.',
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Gagal menambahkan transaksi: $e',
        isError: true,
      );
    }
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> deleteTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final transactionId = transaction['id'];

    if (transactionId == null) {
      showMessage(
        'ID transaksi tidak ditemukan.',
        isError: true,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Transaksi?'),
          content: const Text(
            'Transaksi yang dihapus tidak dapat dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
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

    if (confirm != true) return;

    try {
      await supabase
          .from('transactions')
          .delete()
          .eq('id', transactionId);

      await loadAllData();

      if (!mounted) return;

      showMessage(
        'Transaksi berhasil dihapus.',
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        'Gagal menghapus transaksi: $e',
        isError: true,
      );
    }
  }

  // =========================================================
  // FILTER
  // =========================================================

  List<Map<String, dynamic>> get filteredTransactions {
    if (selectedFilter == 'all') {
      return transactions;
    }

    return transactions.where((transaction) {
      return transaction['type'] == selectedFilter;
    }).toList();
  }

  // =========================================================
  // TOTAL
  // =========================================================

  double get totalIncome {
    return transactions
        .where((transaction) => transaction['type'] == 'income')
        .fold<double>(
          0,
          (total, transaction) {
            return total + toDouble(transaction['amount']);
          },
        );
  }

  double get totalExpense {
    return transactions
        .where((transaction) => transaction['type'] == 'expense')
        .fold<double>(
          0,
          (total, transaction) {
            return total + toDouble(transaction['amount']);
          },
        );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  double parseAmount(String value) {
    final cleaned = value
        .replaceAll('Rp', '')
        .replaceAll('rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    return double.tryParse(cleaned) ?? 0;
  }

  double toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '0',
        ) ??
        0;
  }

  String formatRupiah(dynamic value) {
    final amount = toDouble(value);

    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String dbDate(DateTime date) {
    return DateFormat(
      'yyyy-MM-dd',
    ).format(date);
  }

  String displayDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    try {
      final date = DateTime.parse(
        value.toString(),
      );

      return DateFormat(
        'dd MMM yyyy',
        'id_ID',
      ).format(date);
    } catch (_) {
      return value.toString();
    }
  }

  Map<String, dynamic>? relationMap(
    dynamic value,
  ) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty) {
      final first = value.first;

      if (first is Map) {
        return Map<String, dynamic>.from(first);
      }
    }

    return null;
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red : null,
        ),
      );
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final displayedTransactions = filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadAllData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddTransactionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: loadAllData,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  // =================================================
                  // SUMMARY
                  // =================================================

                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          title: 'Pemasukan',
                          amount: totalIncome,
                          icon: Icons.arrow_downward,
                          iconColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          title: 'Pengeluaran',
                          amount: totalExpense,
                          icon: Icons.arrow_upward,
                          iconColor: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // FILTER
                  // =================================================

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Semua'),
                          selected:
                              selectedFilter == 'all',
                          onSelected: (_) {
                            setState(() {
                              selectedFilter = 'all';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Pemasukan'),
                          selected:
                              selectedFilter == 'income',
                          onSelected: (_) {
                            setState(() {
                              selectedFilter = 'income';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Pengeluaran'),
                          selected:
                              selectedFilter == 'expense',
                          onSelected: (_) {
                            setState(() {
                              selectedFilter = 'expense';
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Daftar Transaksi',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // EMPTY
                  // =================================================

                  if (displayedTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 60,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 70,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada transaksi',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tambahkan transaksi untuk melihat riwayat keuangan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // =================================================
                  // LIST
                  // =================================================

                  ...displayedTransactions.map(
                    (transaction) {
                      final type =
                          transaction['type']
                              ?.toString();

                      final amount =
                          toDouble(
                        transaction['amount'],
                      );

                      final account =
                          relationMap(
                        transaction['accounts'],
                      );

                      final category =
                          relationMap(
                        transaction['categories'],
                      );

                      final accountName =
                          account?['name']
                                  ?.toString() ??
                              'Rekening';

                      final provider =
                          account?['provider']
                                  ?.toString() ??
                              '';

                      final categoryName =
                          category?['name']
                                  ?.toString() ??
                              'Kategori';

                      final isIncome =
                          type == 'income';

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 10,
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
                                    ? Colors.green
                                        .withValues(
                                        alpha: 0.12,
                                      )
                                    : Colors.deepOrange
                                        .withValues(
                                        alpha: 0.12,
                                      ),
                            child: Icon(
                              isIncome
                                  ? Icons
                                      .arrow_downward
                                  : Icons
                                      .arrow_upward,
                              color: isIncome
                                  ? Colors.green
                                  : Colors.deepOrange,
                            ),
                          ),
                          title: Text(
                            categoryName,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                provider.isEmpty
                                    ? accountName
                                    : '$accountName - $provider',
                              ),
                              Text(
                                displayDate(
                                  transaction[
                                      'transaction_date'],
                                ),
                              ),
                              if (transaction[
                                      'description'] !=
                                  null)
                                Text(
                                  transaction[
                                          'description']
                                      .toString(),
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isIncome ? '+' : '-'} ${formatRupiah(amount)}',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  color: isIncome
                                      ? Colors.green
                                      : Colors
                                          .deepOrange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints:
                                    const BoxConstraints(),
                                onPressed: () {
                                  deleteTransaction(
                                    transaction,
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatRupiah(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}