import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfReportScreen extends StatefulWidget {
  const PdfReportScreen({super.key});

  @override
  State<PdfReportScreen> createState() =>
      _PdfReportScreenState();
}

class _PdfReportScreenState
    extends State<PdfReportScreen> {
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
                'Pilih Periode PDF',
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

  Future<Uint8List> generatePdf() async {
    final pdf = pw.Document();

    final green = PdfColor.fromHex(
      '#0B8F55',
    );

    final lightGreen = PdfColor.fromHex(
      '#E9F7F0',
    );

    final balance =
        totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Container(
              padding:
                  const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: green,
                borderRadius:
                    pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment
                        .start,
                children: [
                  pw.Text(
                    'AHMAD FINANCE',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 22,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Laporan Keuangan Bulanan',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceBetween,
              children: [
                pw.Text(
                  'Periode',
                  style: pw.TextStyle(
                    fontWeight:
                        pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  '${monthNames[selectedMonth - 1]} $selectedYear',
                ),
              ],
            ),

            pw.SizedBox(height: 18),

            pw.Row(
              children: [
                pw.Expanded(
                  child: summaryBox(
                    title: 'Pemasukan',
                    value:
                        formatRupiah(totalIncome),
                    color: PdfColors.green,
                    background:
                        PdfColors.green100,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: summaryBox(
                    title: 'Pengeluaran',
                    value:
                        formatRupiah(totalExpense),
                    color: PdfColors.red,
                    background:
                        PdfColors.red100,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: summaryBox(
                    title: 'Saldo Bersih',
                    value:
                        formatRupiah(balance),
                    color: green,
                    background:
                        lightGreen,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            pw.Container(
              padding:
                  const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGreen,
                borderRadius:
                    pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment
                        .spaceBetween,
                children: [
                  pw.Text(
                    'Jumlah Transaksi',
                    style: pw.TextStyle(
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    transactions.length
                        .toString(),
                    style: pw.TextStyle(
                      fontWeight:
                          pw.FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            pw.Text(
              'Detail Transaksi',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight:
                    pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 10),

            if (transactions.isEmpty)
              pw.Container(
                padding:
                    const pw.EdgeInsets.all(20),
                child: pw.Center(
                  child: pw.Text(
                    'Tidak ada transaksi pada periode ini.',
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: [
                  'Tanggal',
                  'Kategori',
                  'Rekening',
                  'Jenis',
                  'Nominal',
                ],
                data: transactions.map(
                  (transaction) {
                    final type =
                        transaction['type']
                                ?.toString() ??
                            '';

                    final amount =
                        double.tryParse(
                              transaction[
                                      'amount']
                                  ?.toString(),
                            ) ??
                            0;

                    final category =
                        relationName(
                      transaction[
                          'categories'],
                      'name',
                    );

                    final account =
                        relationName(
                      transaction[
                          'accounts'],
                      'name',
                    );

                    return [
                      formatDate(
                        transaction[
                                'transaction_date']
                            ?.toString(),
                      ),
                      category,
                      account,
                      type == 'income'
                          ? 'Pemasukan'
                          : 'Pengeluaran',
                      formatRupiah(amount),
                    ];
                  },
                ).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight:
                      pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration:
                    pw.BoxDecoration(
                  color: green,
                ),
                cellStyle:
                    const pw.TextStyle(
                  fontSize: 8,
                ),
                cellAlignment:
                    pw.Alignment.centerLeft,
                border: pw.TableBorder.all(
                  color:
                      PdfColors.grey300,
                  width: 0.5,
                ),
                cellPadding:
                    const pw.EdgeInsets.all(
                  6,
                ),
              ),

            pw.SizedBox(height: 20),

            pw.Align(
              alignment:
                  pw.Alignment.centerRight,
              child: pw.Text(
                'Dibuat oleh Ahmad Finance',
                style: pw.TextStyle(
                  fontSize: 9,
                  color:
                      PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget summaryBox({
    required String title,
    required String value,
    required PdfColor color,
    required PdfColor background,
  }) {
    return pw.Container(
      padding:
          const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius:
            pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight:
                  pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> previewPdf() async {
    if (isLoading) {
      return;
    }

    try {
      final bytes = await generatePdf();

      await Printing.layoutPdf(
        onLayout: (format) async {
          return bytes;
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuat PDF: $e',
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
          'Export PDF',
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
                              Icons.picture_as_pdf,
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
                                  'Periode Laporan',
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
                    'Total Pemasukan',
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
                    'Total Pengeluaran',
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
                          previewPdf,
                      icon: const Icon(
                        Icons.picture_as_pdf,
                      ),
                      label: const Text(
                        'Buat & Preview PDF',
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
                            'Isi PDF',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '• Periode laporan',
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
                            '• Jumlah transaksi',
                          ),
                          Text(
                            '• Detail transaksi',
                          ),
                          Text(
                            '• Kategori',
                          ),
                          Text(
                            '• Rekening',
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