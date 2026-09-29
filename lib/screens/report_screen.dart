import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool isLoading = true;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  List<Map<String, dynamic>> transactions = [];

  double totalIncome = 0;
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  // ================================================================
  // LOAD LAPORAN
  // ================================================================

  Future<void> loadReport() async {
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

      final firstDay = DateTime(
        selectedYear,
        selectedMonth,
        1,
      );

      final lastDay = DateTime(
        selectedYear,
        selectedMonth + 1,
        0,
      );

      final startDate = formatDatabaseDate(
        firstDay,
      );

      final endDate = formatDatabaseDate(
        lastDay,
      );

      final response = await supabase
          .from('transactions')
          .select('''
            id,
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
          .gte(
            'transaction_date',
            startDate,
          )
          .lte(
            'transaction_date',
            endDate,
          )
          .order(
            'transaction_date',
            ascending: false,
          )
          .order(
            'created_at',
            ascending: false,
          );

      final loadedTransactions =
          List<Map<String, dynamic>>.from(
        response,
      );

      double income = 0;
      double expense = 0;

      for (final transaction
          in loadedTransactions) {
        final amount =
            parseAmount(
          transaction['amount'],
        );

        final type =
            transaction['type']
                ?.toString();

        if (type == 'income') {
          income += amount;
        } else if (type == 'expense') {
          expense += amount;
        }
      }

      if (!mounted) return;

      setState(() {
        transactions =
            loadedTransactions;

        totalIncome = income;
        totalExpense = expense;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Gagal memuat laporan: $e',
        isError: true,
      );
    }
  }

  // ================================================================
  // FORMAT DATABASE DATE
  // ================================================================

  String formatDatabaseDate(
    DateTime date,
  ) {
    final year =
        date.year.toString();

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    return '$year-$month-$day';
  }

  // ================================================================
  // FORMAT RUPIAH
  // ================================================================

  String formatRupiah(
    double value,
  ) {
    final rounded =
        value.round();

    final formatted =
        rounded.toString().replaceAllMapped(
              RegExp(
                r'(\d)(?=(\d{3})+(?!\d))',
              ),
              (match) =>
                  '${match[1]}.',
            );

    return 'Rp $formatted';
  }

  // ================================================================
  // PARSE NOMINAL
  // ================================================================

  double parseAmount(
    dynamic value,
  ) {
    return double.tryParse(
          value?.toString() ?? '0',
        ) ??
        0;
  }

  // ================================================================
  // FORMAT TANGGAL
  // ================================================================

  String formatDate(
    String? date,
  ) {
    if (date == null ||
        date.isEmpty) {
      return '-';
    }

    try {
      final parsed =
          DateTime.parse(date);

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
  // NAMA BULAN
  // ================================================================

  String monthName(
    int month,
  ) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return months[month - 1];
  }

  // ================================================================
  // GET CATEGORY
  // ================================================================

  Map<String, dynamic>?
      getCategory(
    Map<String, dynamic>
        transaction,
  ) {
    final category =
        transaction['categories'];

    if (category
        is Map<String, dynamic>) {
      return category;
    }

    if (category is List &&
        category.isNotEmpty) {
      final first =
          category.first;

      if (first
          is Map<String, dynamic>) {
        return first;
      }
    }

    return null;
  }

  // ================================================================
  // GET ACCOUNT
  // ================================================================

  Map<String, dynamic>?
      getAccount(
    Map<String, dynamic>
        transaction,
  ) {
    final account =
        transaction['accounts'];

    if (account
        is Map<String, dynamic>) {
      return account;
    }

    if (account is List &&
        account.isNotEmpty) {
      final first =
          account.first;

      if (first
          is Map<String, dynamic>) {
        return first;
      }
    }

    return null;
  }

  // ================================================================
  // CATEGORY NAME
  // ================================================================

  String getCategoryName(
    Map<String, dynamic>
        transaction,
  ) {
    final category =
        getCategory(transaction);

    return category?['name']
            ?.toString() ??
        'Tanpa Kategori';
  }

  // ================================================================
  // ACCOUNT NAME
  // ================================================================

  String getAccountName(
    Map<String, dynamic>
        transaction,
  ) {
    final account =
        getAccount(transaction);

    if (account == null) {
      return 'Tanpa Rekening';
    }

    final name =
        account['name']
                ?.toString() ??
            '';

    final provider =
        account['provider']
                ?.toString() ??
            '';

    if (provider.isNotEmpty) {
      return '$name • $provider';
    }

    return name;
  }

  // ================================================================
  // SELISIH
  // ================================================================

  double get balance {
    return totalIncome -
        totalExpense;
  }

  // ================================================================
  // JUMLAH TRANSAKSI
  // ================================================================

  int get transactionCount {
    return transactions.length;
  }

  // ================================================================
  // PESAN
  // ================================================================

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
        backgroundColor:
            isError
                ? Colors.red
                : Colors.green,
      ),
    );
  }

  // ================================================================
  // PILIH BULAN
  // ================================================================

  Future<void>
      selectMonth() async {
    int temporaryMonth =
        selectedMonth;

    int temporaryYear =
        selectedYear;

    final result =
        await showDialog<
            Map<String, int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title:
                  const Text(
                'Pilih Periode',
              ),

              content:
                  SizedBox(
                width: 400,

                child:
                    Column(
                  mainAxisSize:
                      MainAxisSize.min,

                  children: [
                    DropdownButtonFormField<
                        int>(
                      initialValue:
                          temporaryMonth,

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Bulan',
                        border:
                            OutlineInputBorder(),
                      ),

                      items:
                          List.generate(
                        12,
                        (index) {
                          final month =
                              index + 1;

                          return DropdownMenuItem<
                              int>(
                            value:
                                month,

                            child:
                                Text(
                              monthName(
                                month,
                              ),
                            ),
                          );
                        },
                      ),

                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setDialogState(
                          () {
                            temporaryMonth =
                                value;
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    DropdownButtonFormField<
                        int>(
                      initialValue:
                          temporaryYear,

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Tahun',
                        border:
                            OutlineInputBorder(),
                      ),

                      items:
                          List.generate(
                        11,
                        (index) {
                          final year =
                              DateTime.now()
                                      .year -
                                  5 +
                                  index;

                          return DropdownMenuItem<
                              int>(
                            value:
                                year,

                            child:
                                Text(
                              year
                                  .toString(),
                            ),
                          );
                        },
                      ),

                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setDialogState(
                          () {
                            temporaryYear =
                                value;
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  child:
                      const Text(
                    'Batal',
                  ),
                ),

                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      {
                        'month':
                            temporaryMonth,
                        'year':
                            temporaryYear,
                      },
                    );
                  },

                  child:
                      const Text(
                    'Terapkan',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      selectedMonth =
          result['month']!;

      selectedYear =
          result['year']!;
    });

    await loadReport();
  }

  // ================================================================
  // TRANSACTION CARD
  // ================================================================

  Widget transactionCard(
    Map<String, dynamic>
        transaction,
  ) {
    final type =
        transaction['type']
                ?.toString() ??
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

    return Container(
      width:
          double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
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
              color:
                  color,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  categoryName,

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  accountName,

                  maxLines:
                      1,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                    fontSize:
                        12,
                  ),
                ),

                if (description
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    description,

                    maxLines:
                        2,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      color:
                          Colors.grey,
                      fontSize:
                          12,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 4,
                ),

                Text(
                  formatDate(
                    date,
                  ),

                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                    fontSize:
                        11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Text(
            '$prefix${formatRupiah(amount)}',

            style:
                TextStyle(
              color:
                  color,

              fontWeight:
                  FontWeight.bold,

              fontSize:
                  13,
            ),
          ),
        ],
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
          const EdgeInsets.all(
        16,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          Icon(
            icon,
            color:
                color,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            title,

            style:
                const TextStyle(
              color:
                  Colors.grey,
              fontSize:
                  13,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            amount,

            maxLines:
                1,

            overflow:
                TextOverflow
                    .ellipsis,

            style:
                const TextStyle(
              fontSize:
                  15,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF5F7F6,
      ),

      appBar:
          AppBar(
        backgroundColor:
            const Color(
          0xFF0F8B4C,
        ),

        foregroundColor:
            Colors.white,

        elevation:
            0,

        title:
            const Text(
          'Laporan Bulanan',

          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
                'Pilih periode',

            onPressed:
                isLoading
                    ? null
                    : selectMonth,

            icon:
                const Icon(
              Icons
                  .calendar_month,
            ),
          ),

          IconButton(
            tooltip:
                'Refresh',

            onPressed:
                isLoading
                    ? null
                    : loadReport,

            icon:
                const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body:
          isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh:
                      loadReport,

                  child:
                      SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    padding:
                        const EdgeInsets
                            .all(
                      16,
                    ),

                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        // ==================================================
                        // PERIODE
                        // ==================================================

                        Container(
                          width:
                              double.infinity,

                          padding:
                              const EdgeInsets
                                  .all(
                            18,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFF0F8B4C,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),

                          child:
                              Row(
                            children: [
                              Container(
                                width:
                                    48,

                                height:
                                    48,

                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white.withValues(
                                    alpha:
                                        0.15,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    14,
                                  ),
                                ),

                                child:
                                    const Icon(
                                  Icons
                                      .calendar_month,
                                  color:
                                      Colors.white,
                                ),
                              ),

                              const SizedBox(
                                width:
                                    12,
                              ),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    const Text(
                                      'Periode Laporan',

                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white70,
                                        fontSize:
                                            13,
                                      ),
                                    ),

                                    const SizedBox(
                                      height:
                                          4,
                                    ),

                                    Text(
                                      '${monthName(selectedMonth)} $selectedYear',

                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize:
                                            20,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                onPressed:
                                    selectMonth,

                                icon:
                                    const Icon(
                                  Icons
                                      .edit_calendar,
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height:
                              18,
                        ),

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
                              width:
                                  12,
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
                          height:
                              12,
                        ),

                        Row(
                          children: [
                            Expanded(
                              child:
                                  summaryCard(
                                title:
                                    'Selisih',

                                amount:
                                    formatRupiah(
                                  balance,
                                ),

                                color:
                                    balance >=
                                            0
                                        ? Colors.green
                                        : Colors.red,

                                icon:
                                    balance >=
                                            0
                                        ? Icons
                                            .trending_up
                                        : Icons
                                            .trending_down,
                              ),
                            ),

                            const SizedBox(
                              width:
                                  12,
                            ),

                            Expanded(
                              child:
                                  summaryCard(
                                title:
                                    'Transaksi',

                                amount:
                                    '$transactionCount transaksi',

                                color:
                                    const Color(
                                  0xFF0F8B4C,
                                ),

                                icon:
                                    Icons
                                        .receipt_long,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height:
                              25,
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
                              'Detail Transaksi',

                              style:
                                  TextStyle(
                                fontSize:
                                    18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            Text(
                              '$transactionCount transaksi',

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
                          height:
                              12,
                        ),

                        // ==================================================
                        // TRANSAKSI
                        // ==================================================

                        if (transactions
                            .isEmpty)
                          Container(
                            width:
                                double.infinity,

                            padding:
                                const EdgeInsets
                                    .all(
                              30,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                16,
                              ),
                            ),

                            child:
                                const Column(
                              children: [
                                Icon(
                                  Icons
                                      .receipt_long_outlined,

                                  size:
                                      60,

                                  color:
                                      Colors.grey,
                                ),

                                SizedBox(
                                  height:
                                      12,
                                ),

                                Text(
                                  'Belum ada transaksi',

                                  style:
                                      TextStyle(
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                SizedBox(
                                  height:
                                      6,
                                ),

                                Text(
                                  'Tidak ada transaksi pada periode ini.',

                                  textAlign:
                                      TextAlign
                                          .center,

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey,
                                    fontSize:
                                        13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children:
                                transactions
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
                          height:
                              30,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}