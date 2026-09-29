import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final supabase = Supabase.instance.client;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  bool isLoading = true;

  double totalIncome = 0;
  double totalExpense = 0;

  int transactionCount = 0;

  List<Map<String, dynamic>> categoryExpenses = [];

  final List<String> monthNames = const [
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

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User belum login.');
      }

      final startDate = DateTime(
        selectedYear,
        selectedMonth,
        1,
      );

      final endDate = DateTime(
        selectedYear,
        selectedMonth + 1,
        0,
      );

      final startString = formatDatabaseDate(startDate);
      final endString = formatDatabaseDate(endDate);

      final response = await supabase
          .from('transactions')
          .select('''
            id,
            type,
            amount,
            transaction_date,
            category_id,
            categories (
              id,
              name,
              type,
              icon
            )
          ''')
          .eq('user_id', user.id)
          .gte('transaction_date', startString)
          .lte('transaction_date', endString)
          .order('transaction_date', ascending: true);

      final List<Map<String, dynamic>> transactions =
          List<Map<String, dynamic>>.from(response);

      double income = 0;
      double expense = 0;

      final Map<String, double> categoryMap = {};

      for (final transaction in transactions) {
        final type = transaction['type']?.toString() ?? '';

        final amount = double.tryParse(
              transaction['amount']?.toString() ?? '0',
            ) ??
            0;

        if (type == 'income') {
          income += amount;
        }

        if (type == 'expense') {
          expense += amount;

          final categoryData = transaction['categories'];

          String categoryName = 'Tanpa Kategori';

          if (categoryData is Map) {
            categoryName =
                categoryData['name']?.toString() ?? 'Tanpa Kategori';
          } else if (categoryData is List &&
              categoryData.isNotEmpty &&
              categoryData.first is Map) {
            categoryName =
                categoryData.first['name']?.toString() ??
                    'Tanpa Kategori';
          }

          categoryMap[categoryName] =
              (categoryMap[categoryName] ?? 0) + amount;
        }
      }

      final sortedCategories = categoryMap.entries.toList()
        ..sort(
          (a, b) => b.value.compareTo(a.value),
        );

      final List<Map<String, dynamic>> categoryResult =
          sortedCategories
              .map(
                (entry) => {
                  'name': entry.key,
                  'amount': entry.value,
                },
              )
              .toList();

      if (!mounted) return;

      setState(() {
        totalIncome = income;
        totalExpense = expense;
        transactionCount = transactions.length;
        categoryExpenses = categoryResult;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Gagal memuat statistik: $e',
        isError: true,
      );
    }
  }

  String formatDatabaseDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String formatRupiah(double value) {
    final rounded = value.round();
    final text = rounded.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(text[i]);
    }

    return 'Rp ${buffer.toString()}';
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : const Color(0xFF0B8F55),
      ),
    );
  }

  void showPeriodPicker() {
    int tempMonth = selectedMonth;
    int tempYear = selectedYear;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Pilih Periode',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: tempMonth,
                    decoration: const InputDecoration(
                      labelText: 'Bulan',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      12,
                      (index) {
                        final month = index + 1;

                        return DropdownMenuItem<int>(
                          value: month,
                          child: Text(monthNames[index]),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        tempMonth = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: tempYear,
                    decoration: const InputDecoration(
                      labelText: 'Tahun',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      11,
                      (index) {
                        final year =
                            DateTime.now().year - 5 + index;

                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        tempYear = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);

                    setState(() {
                      selectedMonth = tempMonth;
                      selectedYear = tempYear;
                    });

                    loadStatistics();
                  },
                  child: const Text('Tampilkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double get balance {
    return totalIncome - totalExpense;
  }

  double get totalCategoryExpense {
    return categoryExpenses.fold(
      0,
      (sum, item) =>
          sum + (item['amount'] as double),
    );
  }

  double getPercentage(double amount, double total) {
    if (total <= 0) {
      return 0;
    }

    return amount / total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Grafik & Statistik',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadStatistics,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadStatistics,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPeriodCard(),

                  const SizedBox(height: 16),

                  _buildSummaryCards(),

                  const SizedBox(height: 16),

                  _buildIncomeExpenseChart(),

                  const SizedBox(height: 16),

                  _buildCategoryChart(),

                  const SizedBox(height: 16),

                  _buildStatisticCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodCard() {
    return Card(
      elevation: 0,
      color: const Color(0xFFE9F7F0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF0B8F55),
              child: Icon(
                Icons.calendar_month,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Periode Statistik',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${monthNames[selectedMonth - 1]} $selectedYear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: showPeriodPicker,
              child: const Text('Ubah'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Pemasukan',
                value: formatRupiah(totalIncome),
                icon: Icons.arrow_downward,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: 'Pengeluaran',
                value: formatRupiah(totalExpense),
                icon: Icons.arrow_upward,
                color: Colors.red,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _summaryCard(
          title: 'Selisih / Saldo Bersih',
          value: formatRupiah(balance),
          icon: balance >= 0
              ? Icons.account_balance_wallet
              : Icons.warning_amber,
          color: balance >= 0
              ? const Color(0xFF0B8F55)
              : Colors.orange,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: fullWidth ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseChart() {
    final total = totalIncome + totalExpense;

    final incomePercentage =
        getPercentage(totalIncome, total);

    final expensePercentage =
        getPercentage(totalExpense, total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Perbandingan Pemasukan & Pengeluaran',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            if (total <= 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Belum ada data transaksi.',
                  ),
                ),
              )
            else
              Column(
                children: [
                  _progressBar(
                    label: 'Pemasukan',
                    amount: totalIncome,
                    percentage: incomePercentage,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 18),

                  _progressBar(
                    label: 'Pengeluaran',
                    amount: totalExpense,
                    percentage: expensePercentage,
                    color: Colors.red,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _progressBar({
    required String label,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              formatRupiah(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor:
                AlwaysStoppedAnimation<Color>(color),
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '${(percentage * 100).toStringAsFixed(1)}%',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengeluaran Berdasarkan Kategori',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            if (categoryExpenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Belum ada pengeluaran pada periode ini.',
                  ),
                ),
              )
            else
              ...categoryExpenses.map(
                (item) {
                  final name =
                      item['name'].toString();

                  final amount =
                      item['amount'] as double;

                  final percentage =
                      getPercentage(
                    amount,
                    totalCategoryExpense,
                  );

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 16,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              formatRupiah(amount),
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 7),

                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          child:
                              LinearProgressIndicator(
                            value: percentage,
                            minHeight: 9,
                            backgroundColor:
                                Colors.grey.shade200,
                            valueColor:
                                const AlwaysStoppedAnimation<
                                    Color>(
                              Color(0xFF0B8F55),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Statistik',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            _statisticRow(
              icon: Icons.receipt_long,
              title: 'Jumlah Transaksi',
              value: transactionCount.toString(),
            ),

            const Divider(),

            _statisticRow(
              icon: Icons.trending_down,
              title: 'Total Pengeluaran',
              value: formatRupiah(totalExpense),
            ),

            const Divider(),

            _statisticRow(
              icon: Icons.trending_up,
              title: 'Total Pemasukan',
              value: formatRupiah(totalIncome),
            ),

            const Divider(),

            _statisticRow(
              icon: Icons.account_balance,
              title: 'Saldo Bersih',
              value: formatRupiah(balance),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statisticRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF0B8F55),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}