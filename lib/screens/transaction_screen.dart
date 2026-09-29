import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() =>
      _TransactionScreenState();
}

class _TransactionScreenState
    extends State<TransactionScreen> {
  final SupabaseClient supabase =
      Supabase.instance.client;

  bool isLoading = true;

  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> accounts = [];
  List<Map<String, dynamic>> categories = [];

  String selectedFilter = 'all';

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  // ================================================================
  // LOAD SEMUA DATA
  // ================================================================

  Future<void> loadAllData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      // ============================================================
      // LOAD REKENING
      // ============================================================

      final accountsResponse = await supabase
          .from('accounts')
          .select(
            'id, name, provider, type, initial_balance',
          )
          .eq('user_id', user.id)
          .order('name');

      // ============================================================
      // LOAD KATEGORI
      // ============================================================

      final categoriesResponse = await supabase
          .from('categories')
          .select(
            'id, name, type, icon',
          )
          .eq('user_id', user.id)
          .order('name');

      // ============================================================
      // LOAD TRANSAKSI
      // ============================================================

      final transactionsResponse =
          await supabase
              .from('transactions')
              .select('''
                id,
                user_id,
                account_id,
                category_id,
                type,
                amount,
                description,
                transaction_date,
                created_at,
                accounts (
                  id,
                  name,
                  provider
                ),
                categories (
                  id,
                  name,
                  type,
                  icon
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

      final loadedAccounts =
          List<Map<String, dynamic>>.from(
        accountsResponse,
      );

      final loadedCategories =
          List<Map<String, dynamic>>.from(
        categoriesResponse,
      );

      final loadedTransactions =
          List<Map<String, dynamic>>.from(
        transactionsResponse,
      );

      if (!mounted) return;

      setState(() {
        accounts = loadedAccounts;
        categories = loadedCategories;
        transactions = loadedTransactions;
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

  // ================================================================
  // FILTER TRANSAKSI
  // ================================================================

  List<Map<String, dynamic>> get filteredTransactions {
    List<Map<String, dynamic>> result =
        List<Map<String, dynamic>>.from(
      transactions,
    );

    // Filter tipe
    if (selectedFilter != 'all') {
      result = result.where((transaction) {
        return transaction['type']?.toString() ==
            selectedFilter;
      }).toList();
    }

    // Filter pencarian
    if (searchQuery.trim().isNotEmpty) {
      final query =
          searchQuery.trim().toLowerCase();

      result = result.where((transaction) {
        final categoryName =
            getCategoryName(transaction)
                .toLowerCase();

        final accountName =
            getAccountName(transaction)
                .toLowerCase();

        final description =
            transaction['description']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final amount =
            transaction['amount']
                    ?.toString()
                    .toLowerCase() ??
                '';

        return categoryName.contains(query) ||
            accountName.contains(query) ||
            description.contains(query) ||
            amount.contains(query);
      }).toList();
    }

    return result;
  }

  // ================================================================
  // TOTAL PEMASUKAN
  // ================================================================

  double get totalIncome {
    double total = 0;

    for (final transaction in transactions) {
      if (transaction['type'] == 'income') {
        total += parseAmount(
          transaction['amount'],
        );
      }
    }

    return total;
  }

  // ================================================================
  // TOTAL PENGELUARAN
  // ================================================================

  double get totalExpense {
    double total = 0;

    for (final transaction in transactions) {
      if (transaction['type'] == 'expense') {
        total += parseAmount(
          transaction['amount'],
        );
      }
    }

    return total;
  }

  // ================================================================
  // PARSE NOMINAL
  // ================================================================

  double parseAmount(dynamic value) {
    return double.tryParse(
          value?.toString() ?? '0',
        ) ??
        0;
  }

  // ================================================================
  // FORMAT RUPIAH
  // ================================================================

  String formatRupiah(double value) {
    final rounded = value.round();

    final formatted = rounded
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );

    return 'Rp $formatted';
  }

  // ================================================================
  // FORMAT TANGGAL
  // ================================================================

  String formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return '-';
    }

    try {
      final parsed = DateTime.parse(date);

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      return '${parsed.day} '
          '${months[parsed.month - 1]} '
          '${parsed.year}';
    } catch (_) {
      return date;
    }
  }

  // ================================================================
  // GET CATEGORY
  // ================================================================

  Map<String, dynamic>? getCategory(
    Map<String, dynamic> transaction,
  ) {
    final category =
        transaction['categories'];

    if (category is Map<String, dynamic>) {
      return category;
    }

    if (category is List &&
        category.isNotEmpty) {
      final first = category.first;

      if (first is Map<String, dynamic>) {
        return first;
      }
    }

    return null;
  }

  // ================================================================
  // GET ACCOUNT
  // ================================================================

  Map<String, dynamic>? getAccount(
    Map<String, dynamic> transaction,
  ) {
    final account =
        transaction['accounts'];

    if (account is Map<String, dynamic>) {
      return account;
    }

    if (account is List &&
        account.isNotEmpty) {
      final first = account.first;

      if (first is Map<String, dynamic>) {
        return first;
      }
    }

    return null;
  }

  // ================================================================
  // CATEGORY NAME
  // ================================================================

  String getCategoryName(
    Map<String, dynamic> transaction,
  ) {
    final category =
        getCategory(transaction);

    return category?['name']?.toString() ??
        'Tanpa Kategori';
  }

  // ================================================================
  // ACCOUNT NAME
  // ================================================================

  String getAccountName(
    Map<String, dynamic> transaction,
  ) {
    final account =
        getAccount(transaction);

    if (account == null) {
      return 'Tanpa Rekening';
    }

    final name =
        account['name']?.toString() ?? '';

    final provider =
        account['provider']?.toString() ?? '';

    if (provider.isNotEmpty) {
      return '$name • $provider';
    }

    return name;
  }

  // ================================================================
  // SHOW MESSAGE
  // ================================================================

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ================================================================
  // TAMBAH TRANSAKSI
  // ================================================================

  Future<void> showAddTransaction() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage(
        'Silakan login terlebih dahulu.',
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

    String? selectedCategoryId;

    String? selectedAccountId =
        accounts.first['id']?.toString();

    DateTime selectedDate =
        DateTime.now();

    final amountController =
        TextEditingController();

    final descriptionController =
        TextEditingController();

    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final filteredCategories =
                categories
                    .where(
                      (category) =>
                          category['type']
                              ?.toString() ==
                          selectedType,
                    )
                    .toList();

            if (selectedCategoryId != null &&
                !filteredCategories.any(
                  (category) =>
                      category['id']
                          ?.toString() ==
                      selectedCategoryId,
                )) {
              selectedCategoryId = null;
            }

            return AlertDialog(
              title: const Text(
                'Tambah Transaksi',
              ),

              content: SizedBox(
                width: 500,

                child:
                    SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      // ==================================================
                      // TIPE
                      // ==================================================

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            selectedType,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Jenis Transaksi',
                          border:
                              OutlineInputBorder(),
                        ),

                        items: const [
                          DropdownMenuItem(
                            value: 'expense',
                            child: Text(
                              'Pengeluaran',
                            ),
                          ),

                          DropdownMenuItem(
                            value: 'income',
                            child: Text(
                              'Pemasukan',
                            ),
                          ),
                        ],

                        onChanged: (value) {
                          if (value ==
                              null) {
                            return;
                          }

                          setDialogState(() {
                            selectedType =
                                value;

                            selectedCategoryId =
                                null;
                          });
                        },
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==================================================
                      // KATEGORI
                      // ==================================================

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            selectedCategoryId,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Kategori',
                          border:
                              OutlineInputBorder(),
                        ),

                        hint: const Text(
                          'Pilih kategori',
                        ),

                        items:
                            filteredCategories
                                .map(
                                  (
                                    category,
                                  ) {
                                    return DropdownMenuItem<
                                        String>(
                                      value:
                                          category[
                                              'id'],
                                      child: Text(
                                        category[
                                                'name']
                                            ?.toString() ??
                                            '',
                                      ),
                                    );
                                  },
                                )
                                .toList(),

                        onChanged: (value) {
                          setDialogState(() {
                            selectedCategoryId =
                                value;
                          });
                        },
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==================================================
                      // REKENING
                      // ==================================================

                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            selectedAccountId,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Rekening',
                          border:
                              OutlineInputBorder(),
                        ),

                        items: accounts
                            .map(
                              (account) {
                                final name =
                                    account[
                                                'name']
                                            ?.toString() ??
                                        '';

                                final provider =
                                    account[
                                                'provider']
                                            ?.toString() ??
                                        '';

                                final title =
                                    provider
                                            .isNotEmpty
                                        ? '$name • $provider'
                                        : name;

                                return DropdownMenuItem<
                                    String>(
                                  value:
                                      account[
                                          'id'],

                                  child:
                                      Text(
                                    title,
                                  ),
                                );
                              },
                            )
                            .toList(),

                        onChanged: (value) {
                          setDialogState(() {
                            selectedAccountId =
                                value;
                          });
                        },
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==================================================
                      // NOMINAL
                      // ==================================================

                      TextField(
                        controller:
                            amountController,

                        keyboardType:
                            TextInputType
                                .number,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Nominal',

                          hintText:
                              'Contoh: 50000',

                          prefixText:
                              'Rp ',

                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==================================================
                      // TANGGAL
                      // ==================================================

                      InkWell(
                        onTap:
                            () async {
                          final picked =
                              await showDatePicker(
                            context:
                                context,

                            initialDate:
                                selectedDate,

                            firstDate:
                                DateTime(
                              2000,
                            ),

                            lastDate:
                                DateTime(
                              2100,
                            ),
                          );

                          if (picked !=
                              null) {
                            setDialogState(
                              () {
                                selectedDate =
                                    picked;
                              },
                            );
                          }
                        },

                        child:
                            InputDecorator(
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Tanggal',
                            border:
                                OutlineInputBorder(),
                          ),

                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,

                            children: [
                              Text(
                                formatDate(
                                  selectedDate
                                      .toIso8601String()
                                      .split(
                                        'T',
                                      )
                                      .first,
                                ),
                              ),

                              const Icon(
                                Icons
                                    .calendar_today,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==================================================
                      // KETERANGAN
                      // ==================================================

                      TextField(
                        controller:
                            descriptionController,

                        maxLines: 3,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Keterangan',

                          hintText:
                              'Contoh: Makan siang',

                          border:
                              OutlineInputBorder(),
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
                      context,
                      false,
                    );
                  },

                  child:
                      const Text(
                    'Batal',
                  ),
                ),

                FilledButton(
                  onPressed: () async {
                    final amount =
                        double.tryParse(
                      amountController
                          .text
                          .replaceAll(
                            '.',
                            '',
                          )
                          .replaceAll(
                            ',',
                            '',
                          )
                          .trim(),
                    );

                    if (selectedCategoryId ==
                        null) {
                      showMessage(
                        'Pilih kategori terlebih dahulu.',
                        isError:
                            true,
                      );

                      return;
                    }

                    if (selectedAccountId ==
                        null) {
                      showMessage(
                        'Pilih rekening terlebih dahulu.',
                        isError:
                            true,
                      );

                      return;
                    }

                    if (amount ==
                            null ||
                        amount <= 0) {
                      showMessage(
                        'Nominal transaksi tidak valid.',
                        isError:
                            true,
                      );

                      return;
                    }

                    try {
                      await supabase
                          .from(
                            'transactions',
                          )
                          .insert({
                        'user_id':
                            user.id,

                        'account_id':
                            selectedAccountId,

                        'category_id':
                            selectedCategoryId,

                        'type':
                            selectedType,

                        'amount':
                            amount,

                        'description':
                            descriptionController
                                    .text
                                    .trim()
                                    .isEmpty
                                ? null
                                : descriptionController
                                    .text
                                    .trim(),

                        'transaction_date':
                            selectedDate
                                .toIso8601String()
                                .split(
                                  'T',
                                )
                                .first,
                      });

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.pop(
                        context,
                        true,
                      );
                    } catch (e) {
                      showMessage(
                        'Gagal menambahkan transaksi: $e',
                        isError:
                            true,
                      );
                    }
                  },

                  child:
                      const Text(
                    'Simpan',
                  ),
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

      showMessage(
        'Transaksi berhasil ditambahkan.',
      );
    }
  }

  // ================================================================
  // HAPUS TRANSAKSI
  // ================================================================

  Future<void> deleteTransaction(
    String transactionId,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Transaksi?',
          ),

          content: const Text(
            'Transaksi yang dihapus tidak dapat dikembalikan.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },

              child:
                  const Text('Batal'),
            ),

            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    Colors.red,
              ),

              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              child:
                  const Text('Hapus'),
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
            transactionId,
          );

      await loadAllData();

      showMessage(
        'Transaksi berhasil dihapus.',
      );
    } catch (e) {
      showMessage(
        'Gagal menghapus transaksi: $e',
        isError: true,
      );
    }
  }

  // ================================================================
  // TRANSACTION CARD
  // ================================================================

  Widget transactionCard(
    Map<String, dynamic> transaction,
  ) {
    final type =
        transaction['type']?.toString() ??
            '';

    final amount =
        parseAmount(
      transaction['amount'],
    );

    final isIncome =
        type == 'income';

    final color =
        isIncome
            ? Colors.green
            : Colors.red;

    final icon =
        isIncome
            ? Icons.arrow_downward
            : Icons.arrow_upward;

    final prefix =
        isIncome ? '+' : '-';

    final categoryName =
        getCategoryName(
      transaction,
    );

    final accountName =
        getAccountName(
      transaction,
    );

    final description =
        transaction['description']
                ?.toString() ??
            '';

    final date =
        transaction['transaction_date']
            ?.toString();

    final transactionId =
        transaction['id']
            ?.toString();

    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(14),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ==========================================================
          // ICON
          // ==========================================================

          Container(
            width: 46,
            height: 46,

            decoration:
                BoxDecoration(
              color:
                  color.withValues(
                alpha: 0.12,
              ),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ==========================================================
          // INFORMASI
          // ==========================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  categoryName,

                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  accountName,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                if (description
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    description,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 4,
                ),

                Text(
                  formatDate(date),

                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ==========================================================
          // NOMINAL + DELETE
          // ==========================================================

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.end,

            children: [
              Text(
                '$prefix${formatRupiah(amount)}',

                style: TextStyle(
                  color: color,

                  fontSize: 13,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              if (transactionId != null)
                IconButton(
                  tooltip:
                      'Hapus transaksi',

                  visualDensity:
                      VisualDensity
                          .compact,

                  padding:
                      EdgeInsets.zero,

                  constraints:
                      const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),

                  onPressed: () {
                    deleteTransaction(
                      transactionId,
                    );
                  },

                  icon:
                      const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // FILTER CHIP
  // ================================================================

  Widget filterChip({
    required String value,
    required String label,
  }) {
    return ChoiceChip(
      label: Text(label),

      selected:
          selectedFilter == value,

      onSelected: (selected) {
        if (!selected) return;

        setState(() {
          selectedFilter = value;
        });
      },

      selectedColor:
          const Color(0xFF0F8B4C)
              .withValues(
        alpha: 0.15,
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final displayedTransactions =
        filteredTransactions;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7F6),

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0F8B4C),

        foregroundColor:
            Colors.white,

        elevation: 0,

        title: const Text(
          'Riwayat Transaksi',

          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Refresh',

            onPressed:
                isLoading
                    ? null
                    : loadAllData,

            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      // ============================================================
      // FAB
      // ============================================================

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            const Color(0xFF0F8B4C),

        foregroundColor:
            Colors.white,

        onPressed:
            isLoading
                ? null
                : showAddTransaction,

        icon:
            const Icon(
          Icons.add,
        ),

        label:
            const Text(
          'Tambah',
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh:
                  loadAllData,

              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.all(
                  16,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    // ==================================================
                    // SUMMARY
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child:
                              summaryCard(
                            title:
                                'Pemasukan',

                            amount:
                                formatRupiah(
                              totalIncome,
                            ),

                            color:
                                Colors.green,

                            icon:
                                Icons
                                    .arrow_downward,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child:
                              summaryCard(
                            title:
                                'Pengeluaran',

                            amount:
                                formatRupiah(
                              totalExpense,
                            ),

                            color:
                                Colors.red,

                            icon:
                                Icons
                                    .arrow_upward,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ==================================================
                    // SEARCH
                    // ==================================================

                    TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery =
                              value;
                        });
                      },

                      decoration:
                          InputDecoration(
                        hintText:
                            'Cari transaksi...',

                        prefixIcon:
                            const Icon(
                          Icons.search,
                        ),

                        suffixIcon:
                            searchQuery
                                    .isNotEmpty
                                ? IconButton(
                                    onPressed:
                                        () {
                                      setState(
                                        () {
                                          searchQuery =
                                              '';
                                        },
                                      );
                                    },

                                    icon:
                                        const Icon(
                                      Icons
                                          .clear,
                                    ),
                                  )
                                : null,

                        filled:
                            true,

                        fillColor:
                            Colors.white,

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),

                          borderSide:
                              BorderSide
                                  .none,
                        ),

                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),

                          borderSide:
                              BorderSide
                                  .none,
                        ),

                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),

                          borderSide:
                              const BorderSide(
                            color:
                                Color(
                              0xFF0F8B4C,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // FILTER
                    // ==================================================

                    SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,

                      child: Row(
                        children: [
                          filterChip(
                            value: 'all',
                            label:
                                'Semua',
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          filterChip(
                            value:
                                'income',
                            label:
                                'Pemasukan',
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          filterChip(
                            value:
                                'expense',
                            label:
                                'Pengeluaran',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // JUDUL
                    // ==================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                      children: [
                        const Text(
                          'Daftar Transaksi',

                          style:
                              TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(
                          '${displayedTransactions.length} transaksi',

                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                            fontSize:
                                12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==================================================
                    // LIST TRANSAKSI
                    // ==================================================

                    if (displayedTransactions
                        .isEmpty)
                      emptyState()
                    else
                      Column(
                        children:
                            displayedTransactions
                                .map(
                                  (
                                    transaction,
                                  ) =>
                                      transactionCard(
                                    transaction,
                                  ),
                                )
                                .toList(),
                      ),

                    const SizedBox(
                      height: 80,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ================================================================
  // SUMMARY CARD
  // ================================================================

  Widget summaryCard({
    required String title,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(16),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            color: color,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            title,

            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            amount,

            maxLines: 1,

            overflow:
                TextOverflow.ellipsis,

            style:
                const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget emptyState() {
    String title =
        'Belum ada transaksi';

    String subtitle =
        'Tambahkan transaksi untuk melihat riwayat keuangan.';

    if (searchQuery.trim().isNotEmpty) {
      title =
          'Transaksi tidak ditemukan';

      subtitle =
          'Coba gunakan kata pencarian yang berbeda.';
    } else if (selectedFilter ==
        'income') {
      title =
          'Belum ada pemasukan';

      subtitle =
          'Belum terdapat transaksi pemasukan.';
    } else if (selectedFilter ==
        'expense') {
      title =
          'Belum ada pengeluaran';

      subtitle =
          'Belum terdapat transaksi pengeluaran.';
    }

    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(30),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons
                .receipt_long_outlined,

            size: 60,

            color: Colors.grey,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            title,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            subtitle,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}