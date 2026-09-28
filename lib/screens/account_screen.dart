import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> accounts = [];

  bool isLoading = true;

  final List<Map<String, String>> accountTypes = [
    {
      'value': 'bank',
      'label': 'Bank',
    },
    {
      'value': 'ewallet',
      'label': 'E-Wallet',
    },
    {
      'value': 'cash',
      'label': 'Tunai',
    },
    {
      'value': 'card',
      'label': 'Kartu',
    },
    {
      'value': 'other',
      'label': 'Lainnya',
    },
  ];

  final Map<String, List<String>> providers = {
    'bank': [
      'BCA',
      'BRI',
      'BNI',
      'Bank Mandiri',
      'BTN',
      'BSI',
      'Bank Jago',
      'Bank Syariah Indonesia',
      'Bank Danamon',
      'Bank CIMB Niaga',
      'Bank Permata',
      'Bank OCBC',
      'Bank Maybank',
      'Bank Mega',
      'Bank Panin',
      'Bank Sinarmas',
      'Bank Bukopin',
      'Bank BTPN',
      'BTPN Syariah',
      'Jenius',
      'blu by BCA Digital',
      'SeaBank',
      'Bank Neo Commerce',
      'Bank Raya',
      'Bank Muamalat',
      'Bank Aceh',
      'Bank Sumut',
      'Bank Nagari',
      'Bank Riau Kepri',
      'Bank Jambi',
      'Bank Bengkulu',
      'Bank Sumsel Babel',
      'Bank Lampung',
      'Bank DKI',
      'Bank BJB',
      'Bank Jateng',
      'Bank DIY',
      'Bank Jatim',
      'Bank Banten',
      'Bank Kaltimtara',
      'Bank Kalbar',
      'Bank Kalsel',
      'Bank Kalteng',
      'Bank Kaltim',
      'Bank Sulselbar',
      'Bank SulutGo',
      'Bank Sulteng',
      'Bank Maluku Malut',
      'Bank Papua',
      'Lainnya',
    ],
    'ewallet': [
      'DANA',
      'GoPay',
      'OVO',
      'ShopeePay',
      'LinkAja',
      'iSaku',
      'Sakuku',
      'JakOne Pay',
      'MotionPay',
      'Lainnya',
    ],
    'cash': [
      'Tunai',
    ],
    'card': [
      'Kartu Debit',
      'Kartu Kredit',
      'Lainnya',
    ],
    'other': [
      'Lainnya',
    ],
  };

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        return;
      }

      final response = await supabase
          .from('accounts')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        accounts = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil rekening: $e',
          ),
        ),
      );
    }
  }

  Future<void> addAccount() async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    String selectedType = 'bank';
    String selectedProvider = providers['bank']!.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentProviders =
                providers[selectedType] ?? ['Lainnya'];

            if (!currentProviders.contains(selectedProvider)) {
              selectedProvider = currentProviders.first;
            }

            return AlertDialog(
              title: const Text('Tambah Rekening'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Rekening',
                        hintText: 'Contoh: Tabungan Utama',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Jenis',
                        border: OutlineInputBorder(),
                      ),
                      items: accountTypes.map((type) {
                        return DropdownMenuItem(
                          value: type['value'],
                          child: Text(type['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedType = value;
                          selectedProvider =
                              providers[value]!.first;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: selectedProvider,
                      decoration: const InputDecoration(
                        labelText: 'Penyedia',
                        border: OutlineInputBorder(),
                      ),
                      items: currentProviders.map((provider) {
                        return DropdownMenuItem(
                          value: provider,
                          child: Text(provider),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;

                        setDialogState(() {
                          selectedProvider = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: balanceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Saldo Awal',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
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
                    final user =
                        supabase.auth.currentUser;

                    if (user == null) return;

                    if (nameController.text.trim().isEmpty) {
                      return;
                    }

                    final balance = double.tryParse(
                          balanceController.text
                              .replaceAll(',', ''),
                        ) ??
                        0;

                    try {
                      await supabase
                          .from('accounts')
                          .insert({
                        'user_id': user.id,
                        'name':
                            nameController.text.trim(),
                        'type': selectedType,
                        'provider':
                            selectedProvider,
                        'initial_balance': balance,
                      });

                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              'Gagal menambah rekening: $e',
                            ),
                          ),
                        );
                      }
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
    balanceController.dispose();

    if (result == true) {
      loadAccounts();
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await supabase
          .from('accounts')
          .delete()
          .eq('id', id);

      loadAccounts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus rekening: $e',
          ),
        ),
      );
    }
  }

  String formatRupiah(dynamic value) {
    final number =
        double.tryParse(value.toString()) ?? 0;

    final formatted =
        number.toStringAsFixed(0);

    final chars = formatted.split('').reversed.toList();

    final result = <String>[];

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result.add('.');
      }

      result.add(chars[i]);
    }

    return 'Rp ${result.reversed.join()}';
  }

  IconData getAccountIcon(String type) {
    switch (type) {
      case 'bank':
        return Icons.account_balance;

      case 'ewallet':
        return Icons.account_balance_wallet;

      case 'cash':
        return Icons.payments;

      case 'card':
        return Icons.credit_card;

      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekening'),
        backgroundColor: const Color(0xFF0B8F55),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadAccounts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: addAccount,
        backgroundColor: const Color(0xFF0B8F55),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Rekening'),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : accounts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Belum ada rekening',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tambahkan rekening, bank, e-wallet, atau uang tunai.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadAccounts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account =
                          accounts[index];

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFF0B8F55),
                            child: Icon(
                              getAccountIcon(
                                account['type']
                                    .toString(),
                              ),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            account['name']
                                .toString(),
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${account['provider']} • ${account['type']}',
                          ),
                          trailing: Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .end,
                            children: [
                              Text(
                                formatRupiah(
                                  account[
                                      'initial_balance'],
                                ),
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  deleteAccount(
                                    account['id']
                                        .toString(),
                                  );
                                },
                                child: const Icon(
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
                ),
    );
  }
}