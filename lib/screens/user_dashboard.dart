import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_screen.dart';
import 'category_screen.dart';
import 'transaction_screen.dart';
import 'report_screen.dart';
import 'statistics_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;

  double totalBalance = 0;
  double totalIncome = 0;
  double totalExpense = 0;

  List<Map<String, dynamic>> recentTransactions = [];

  int selectedBottomIndex = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
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
          .select(
            'id, name, provider, type, initial_balance',
          )
          .eq('user_id', user.id);

      final transactionsResponse = await supabase
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
          .order(
            'transaction_date',
            ascending: false,
          )
          .order(
            'created_at',
            ascending: false,
          );

      final accounts =
          List<Map<String, dynamic>>.from(
        accountsResponse,
      );

      final transactions =
          List<Map<String, dynamic>>.from(
        transactionsResponse,
      );

      double balance = 0;
      double income = 0;
      double expense = 0;

      for (final account in accounts) {
        final initialBalance =
            double.tryParse(
                  account['initial_balance']
                          ?.toString() ??
                      '0',
                ) ??
                0;

        balance += initialBalance;
      }

      for (final transaction in transactions) {
        final type =
            transaction['type']?.toString() ?? '';

        final amount =
            double.tryParse(
                  transaction['amount']
                          ?.toString() ??
                      '0',
                ) ??
                0;

        if (type == 'income') {
          income += amount;
          balance += amount;
        } else if (type == 'expense') {
          expense += amount;
          balance -= amount;
        }
      }

      if (!mounted) return;

      setState(() {
        totalBalance = balance;
        totalIncome = income;
        totalExpense = expense;

        recentTransactions =
            transactions.take(5).toList();

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        'Gagal memuat dashboard: $e',
        isError: true,
      );
    }
  }

  Future<void> openPage(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );

    await loadDashboard();
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

  String getRelationName(
    dynamic relation,
    String field,
  ) {
    if (relation is Map) {
      return relation[field]?.toString() ?? '-';
    }

    if (relation is List &&
        relation.isNotEmpty &&
        relation.first is Map) {
      return relation.first[field]?.toString() ?? '-';
    }

    return '-';
  }

  IconData getTransactionIcon(
    String type,
  ) {
    if (type == 'income') {
      return Icons.arrow_downward;
    }

    return Icons.arrow_upward;
  }

  Color getTransactionColor(
    String type,
  ) {
    if (type == 'income') {
      return Colors.green;
    }

    return Colors.red;
  }

  void handleBottomNavigation(int index) {
    setState(() {
      selectedBottomIndex = index;
    });

    if (index == 0) {
      return;
    }

    if (index == 1) {
      openPage(
        const TransactionScreen(),
      );

      setState(() {
        selectedBottomIndex = 0;
      });

      return;
    }

    if (index == 2) {
      openPage(
        const ReportScreen(),
      );

      setState(() {
        selectedBottomIndex = 0;
      });

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ahmad Finance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'accounts') {
                openPage(
                  const AccountScreen(),
                );
              }

              if (value == 'categories') {
                openPage(
                  const CategoryScreen(),
                );
              }

              if (value == 'transactions') {
                openPage(
                  const TransactionScreen(),
                );
              }

              if (value == 'reports') {
                openPage(
                  const ReportScreen(),
                );
              }

              if (value == 'statistics') {
                openPage(
                  const StatisticsScreen(),
                );
              }

              if (value == 'logout') {
                logout();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'accounts',
                  child: ListTile(
                    leading:
                        Icon(Icons.account_balance),
                    title: Text('Rekening'),
                  ),
                ),
                PopupMenuItem(
                  value: 'categories',
                  child: ListTile(
                    leading:
                        Icon(Icons.category),
                    title: Text('Kategori'),
                  ),
                ),
                PopupMenuItem(
                  value: 'transactions',
                  child: ListTile(
                    leading:
                        Icon(Icons.receipt_long),
                    title: Text('Transaksi'),
                  ),
                ),
                PopupMenuItem(
                  value: 'reports',
                  child: ListTile(
                    leading:
                        Icon(Icons.assessment),
                    title: Text('Laporan Bulanan'),
                  ),
                ),
                PopupMenuItem(
                  value: 'statistics',
                  child: ListTile(
                    leading:
                        Icon(Icons.bar_chart),
                    title: Text('Grafik & Statistik'),
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Colors.red,
                    ),
                    title: Text('Logout'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _buildWelcomeCard(),

                  const SizedBox(height: 16),

                  _buildBalanceCard(),

                  const SizedBox(height: 16),

                  _buildIncomeExpense(),

                  const SizedBox(height: 20),

                  _buildQuickMenu(),

                  const SizedBox(height: 20),

                  _buildRecentTransactions(),
                ],
              ),
            ),
      bottomNavigationBar:
          NavigationBar(
        selectedIndex: selectedBottomIndex,
        onDestinationSelected:
            handleBottomNavigation,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.receipt_long_outlined),
            selectedIcon:
                Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon:
                Icon(Icons.assessment_outlined),
            selectedIcon:
                Icon(Icons.assessment),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final email =
        supabase.auth.currentUser?.email ??
            'Pengguna';

    return Card(
      color: const Color(0xFFE9F7F0),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor:
                  Color(0xFF0B8F55),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selamat datang 👋',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
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

  Widget _buildBalanceCard() {
    return Card(
      color: const Color(0xFF0B8F55),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Saldo',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatRupiah(totalBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saldo otomatis dari rekening + transaksi',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeExpense() {
    return Row(
      children: [
        Expanded(
          child: _moneyCard(
            title: 'Pemasukan',
            value: totalIncome,
            icon: Icons.arrow_downward,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _moneyCard(
            title: 'Pengeluaran',
            value: totalExpense,
            icon: Icons.arrow_upward,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _moneyCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatRupiah(value),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenu() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Utama',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
          children: [
            _menuItem(
              icon: Icons.receipt_long,
              title: 'Transaksi',
              onTap: () {
                openPage(
                  const TransactionScreen(),
                );
              },
            ),
            _menuItem(
              icon: Icons.account_balance,
              title: 'Rekening',
              onTap: () {
                openPage(
                  const AccountScreen(),
                );
              },
            ),
            _menuItem(
              icon: Icons.category,
              title: 'Kategori',
              onTap: () {
                openPage(
                  const CategoryScreen(),
                );
              },
            ),
            _menuItem(
              icon: Icons.assessment,
              title: 'Laporan',
              onTap: () {
                openPage(
                  const ReportScreen(),
                );
              },
            ),
            _menuItem(
              icon: Icons.bar_chart,
              title: 'Statistik',
              onTap: () {
                openPage(
                  const StatisticsScreen(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor:
                  const Color(0xFFE9F7F0),
              child: Icon(
                icon,
                color:
                    const Color(0xFF0B8F55),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Transaksi Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                openPage(
                  const TransactionScreen(),
                );
              },
              child: const Text('Lihat Semua'),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (recentTransactions.isEmpty)
          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 45,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Belum ada transaksi.',
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentTransactions.map(
            (transaction) {
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
                  getRelationName(
                transaction['categories'],
                'name',
              );

              final account =
                  getRelationName(
                transaction['accounts'],
                'name',
              );

              final description =
                  transaction['description']
                          ?.toString() ??
                      '';

              final date =
                  formatDate(
                transaction['transaction_date']
                    ?.toString(),
              );

              final color =
                  getTransactionColor(type);

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        color.withValues(
                      alpha: 0.12,
                    ),
                    child: Icon(
                      getTransactionIcon(
                        type,
                      ),
                      color: color,
                    ),
                  ),
                  title: Text(
                    category,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '$account • $date'
                    '${description.isNotEmpty ? '\n$description' : ''}',
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                  isThreeLine:
                      description.isNotEmpty,
                  trailing: Text(
                    '${type == 'income' ? '+' : '-'} ${formatRupiah(amount)}',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> logout() async {
    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }
}