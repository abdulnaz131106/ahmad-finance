import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExcelReportScreen extends StatefulWidget {
  const ExcelReportScreen({super.key});

  @override
  State<ExcelReportScreen> createState() =>
      _ExcelReportScreenState();
}

class _ExcelReportScreenState
    extends State<ExcelReportScreen> {
  final supabase = Supabase.instance.client;

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  bool isLoading = false;

  double totalIncome = 0;
  double totalExpense = 0;

  List<Map<String, dynamic>> transactions = [];

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
    loadReport();
  }

  String databaseDate(DateTime date) {
    final month =
        date.month.toString().padLeft(2, '0');

    final day =
        date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String formatRupiah(double value) {
    final rounded = value.round();
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

  String relationName(
    dynamic relation,
    String field,
  ) {
    if (relation is Map) {
      return relation[field]?.toString() ?? '-';
    }

    if (relation is List &&
        relation.isNotEmpty &&
        relation.first is Map) {
      return relation.first[field]?.toString() ??
          '-';
    }

    return '-';
  }

  Future<void> loadReport() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception(
          'User belum login.',
        );
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
            databaseDate(startDate),
          )
          .lte(
            'transaction_date',
            databaseDate(endDate),
          )
          .order(
            'transaction_date',
            ascending: false,
          )
          .order(
            'created_at',
            ascending: false,
          );

      final result =
          List<Map<String, dynamic>>.from(
        response,
      );

      double income = 0;
      double expense = 0;

      for (final transaction in result) {
        final amount =
            double.tryParse(
                  transaction['amount']
                          ?.toString() ??
                      '0',
                ) ??
                0;

        final type =
            transaction['type']?.toString() ??
                '';

        if (type == 'income') {
          income += amount;
        } else if (type == 'expense') {
          expense += amount;
        }
      }

      if (!mounted) return;

      setState(() {
        transactions = result;
        totalIncome = income;
        totalExpense = expense;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat laporan: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> selectPeriod() async {
    int tempMonth = selectedMonth;
    int tempYear = selectedYear;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Pilih Periode Excel',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: tempMonth,
                    decoration:
                        const InputDecoration(
                      labelText: 'Bulan',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: List.generate(
                      12,
                      (index) {
                        final month =
                            index + 1;

                        return DropdownMenuItem<
                            int>(
                          value: month,
                          child: Text(
                            monthNames[index],
                          ),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        tempMonth = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: tempYear,
                    decoration:
                        const InputDecoration(
                      labelText: 'Tahun',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: List.generate(
                      11,
                      (index) {
                        final year =
                            DateTime.now().year -
                                5 +
                                index;

                        return DropdownMenuItem<
                            int>(
                          value: year,
                          child: Text(
                            year.toString(),
                          ),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

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

                    loadReport();
                  },
                  child: const Text(
                    'Tampilkan',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> exportExcel() async {
    if (isLoading) {
      return;
    }

    try {
      final excel = Excel.createExcel();

      final Sheet sheet =
          excel['Laporan Keuangan'];

      final summarySheet =
          excel['Ringkasan'];

      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex:
            '#0B8F55',
        fontColorHex: '#FFFFFF',
        horizontalAlign:
            HorizontalAlign.Center,
        verticalAlign:
            VerticalAlign.Center,
      );

      final titleStyle = CellStyle(
        bold: true,
        fontSize: 18,
        fontColorHex: '#0B8F55',
      );

      final subTitleStyle = CellStyle(
        bold: true,
        fontSize: 12,
      );

      final incomeStyle = CellStyle(
        bold: true,
        fontColorHex: '#16803A',
      );

      final expenseStyle = CellStyle(
        bold: true,
        fontColorHex: '#C62828',
      );

      final balanceStyle = CellStyle(
        bold: true,
        fontColorHex: '#0B8F55',
      );

      // ==============================
      // SHEET RINGKASAN
      // ==============================

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: 0,
            ),
          )
          .value = TextCellValue(
        'AHMAD FINANCE',
      );

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: 0,
            ),
          )
          .cellStyle = titleStyle;

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: 1,
            ),
          )
          .value = TextCellValue(
        'Laporan Keuangan Bulanan',
      );

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: 2,
            ),
          )
          .value = TextCellValue(
        'Periode',
      );

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: 2,
            ),
          )
          .value = TextCellValue(
        '${monthNames[selectedMonth - 1]} $selectedYear',
      );

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: 4,
            ),
          )
          .value = TextCellValue(
        'Total Pemasukan',
      );

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: 4,
            ),
          )
          .value = DoubleCellValue(
        totalIncome,
      );

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: 4,
            ),
          )
          .cellStyle = incomeStyle;

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: 5,
            ),
          )
          .value = TextCellValue(
        'Total Pengeluaran',
      );

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: 5,
            ),
          )
          .value = DoubleCellValue(
        totalExpense,
      );

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: 5,
            ),
          )
          .cellStyle = expenseStyle;

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: 6,
            ),
          )
          .value = TextCellValue(
        'Saldo Bersih',
      );

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: 6,
            ),
          )
          .value = DoubleCellValue(
        totalIncome - totalExpense,
      );

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: 6,
            ),
          )
          .cellStyle = balanceStyle;

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: 7,
            ),
          )
          .value = TextCellValue(
        'Jumlah Transaksi',
      );

      summarySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: 7,
            ),
          )
          .value = IntCellValue(
        transactions.length,
      );

      // Lebar kolom ringkasan
      summarySheet.setColumnWidth(
        0,
        25,
      );

      summarySheet.setColumnWidth(
        1,
        25,
      );

      // ==============================
      // SHEET TRANSAKSI
      // ==============================

      final headers = [
        'No',
        'Tanggal',
        'Kategori',
        'Rekening',
        'Penyedia',
        'Jenis',
        'Nominal',
        'Keterangan',
      ];

      for (int i = 0;
          i < headers.length;
          i++) {
        final cell =
            sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: i,
            rowIndex: 0,
          ),
        );

        cell.value =
            TextCellValue(headers[i]);

        cell.cellStyle = headerStyle;
      }

      for (int i = 0;
          i < transactions.length;
          i++) {
        final transaction =
            transactions[i];

        final type =
            transaction['type']
                    ?.toString() ??
                '';

        final amount =
            double.tryParse(
                  transaction['amount']
                          ?.toString() ??
                      '0',
                ) ??
                0;

        final category =
            relationName(
          transaction['categories'],
          'name',
        );

        final account =
            relationName(
          transaction['accounts'],
          'name',
        );

        final provider =
            relationName(
          transaction['accounts'],
          'provider',
        );

        final description =
            transaction['description']
                    ?.toString() ??
                '';

        final row = i + 1;

        final values = [
          IntCellValue(i + 1),
          TextCellValue(
            formatDate(
              transaction[
                      'transaction_date']
                  ?.toString(),
            ),
          ),
          TextCellValue(category),
          TextCellValue(account),
          TextCellValue(provider),
          TextCellValue(
            type == 'income'
                ? 'Pemasukan'
                : 'Pengeluaran',
          ),
          DoubleCellValue(amount),
          TextCellValue(description),
        ];

        for (int column = 0;
            column < values.length;
            column++) {
          final cell =
              sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: column,
              rowIndex: row,
            ),
          );

          cell.value = values[column];

          if (column == 5) {
            cell.cellStyle = type ==
                    'income'
                ? incomeStyle
                : expenseStyle;
          }
        }
      }

      // Lebar kolom
      sheet.setColumnWidth(0, 7);
      sheet.setColumnWidth(1, 15);
      sheet.setColumnWidth(2, 22);
      sheet.setColumnWidth(3, 22);
      sheet.setColumnWidth(4, 18);
      sheet.setColumnWidth(5, 16);
      sheet.setColumnWidth(6, 20);
      sheet.setColumnWidth(7, 30);

      // ==============================
      // SHEET KATEGORI PENGELUARAN
      // ==============================

      final categorySheet =
          excel['Pengeluaran Kategori'];

      categorySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: 0,
            ),
          )
          .value = TextCellValue(
        'Kategori',
      );

      categorySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: 0,
            ),
          )
          .value = TextCellValue(
        'Total Pengeluaran',
      );

      categorySheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 2,
              rowIndex: 0,
            ),
          )
          .value = TextCellValue(
        'Persentase',
      );

      for (int i = 0; i < 3; i++) {
        categorySheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: i,
                rowIndex: 0,
              ),
            )
            .cellStyle = headerStyle;
      }

      final Map<String, double>
          categoryTotals = {};

      for (final transaction
          in transactions) {
        if (transaction['type']
                ?.toString() !=
            'expense') {
          continue;
        }

        final category =
            relationName(
          transaction['categories'],
          'name',
        );

        final amount =
            double.tryParse(
                  transaction['amount']
                          ?.toString() ??
                      '0',
                ) ??
                0;

        categoryTotals[category] =
            (categoryTotals[category] ??
                    0) +
                amount;
      }

      final sortedCategories =
          categoryTotals.entries.toList()
            ..sort(
              (a, b) =>
                  b.value.compareTo(
                a.value,
              ),
            );

      for (int i = 0;
          i < sortedCategories.length;
          i++) {
        final entry =
            sortedCategories[i];

        final row = i + 1;

        categorySheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 0,
                rowIndex: row,
              ),
            )
            .value = TextCellValue(
          entry.key,
        );

        categorySheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 1,
                rowIndex: row,
              ),
            )
            .value = DoubleCellValue(
          entry.value,
        );

        final percentage =
            totalExpense > 0
                ? entry.value /
                    totalExpense
                : 0;

        categorySheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: 2,
                rowIndex: row,
              ),
            )
            .value = DoubleCellValue(
          percentage,
        );
      }

      categorySheet.setColumnWidth(
        0,
        25,
      );

      categorySheet.setColumnWidth(
        1,
        25,
      );

      categorySheet.setColumnWidth(
        2,
        15,
      );

      // ==============================
      // EXPORT
      // ==============================

      final Uint8List? fileBytes =
          excel.save();

      if (fileBytes == null) {
        throw Exception(
          'Gagal membuat file Excel.',
        );
      }

      final fileName =
          'Ahmad_Finance_${selectedYear}_${selectedMonth.toString().padLeft(2, '0')}.xlsx';

      await Printing.sharePdf(
        bytes: fileBytes,
        filename: fileName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'File Excel berhasil dibuat.',
          ),
          backgroundColor:
              Color(0xFF0B8F55),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuat Excel: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance =
        totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Export Excel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadReport,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadReport,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.all(16),
                children: [
                  Card(
                    color:
                        const Color(0xFFE9F7F0),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        16,
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor:
                                Color(0xFF0B8F55),
                            child: Icon(
                              Icons.table_chart,
                              color:
                                  Colors.white,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'Periode Export',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors
                                        .black54,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  '${monthNames[selectedMonth - 1]} $selectedYear',
                                  style:
                                      const TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed:
                                selectPeriod,
                            child: const Text(
                              'Ubah',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _summaryCard(
                    'Pemasukan',
                    formatRupiah(
                      totalIncome,
                    ),
                    Colors.green,
                    Icons.arrow_downward,
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  _summaryCard(
                    'Pengeluaran',
                    formatRupiah(
                      totalExpense,
                    ),
                    Colors.red,
                    Icons.arrow_upward,
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  _summaryCard(
                    'Saldo Bersih',
                    formatRupiah(balance),
                    balance >= 0
                        ? const Color(
                            0xFF0B8F55,
                          )
                        : Colors.orange,
                    Icons.account_balance_wallet,
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  _summaryCard(
                    'Jumlah Transaksi',
                    transactions.length
                        .toString(),
                    Colors.blue,
                    Icons.receipt_long,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed:
                          exportExcel,
                      icon: const Icon(
                        Icons.table_chart,
                      ),
                      label: const Text(
                        'Export ke Excel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  const Card(
                    child: Padding(
                      padding:
                          EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            'Isi File Excel',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '• Sheet Ringkasan',
                          ),
                          Text(
                            '• Sheet Laporan Transaksi',
                          ),
                          Text(
                            '• Sheet Pengeluaran Kategori',
                          ),
                          Text(
                            '• Total pemasukan',
                          ),
                          Text(
                            '• Total pengeluaran',
                          ),
                          Text(
                            '• Saldo bersih',
                          ),
                          Text(
                            '• Detail rekening',
                          ),
                          Text(
                            '• Detail kategori',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              color.withValues(alpha: 0.12),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}