import 'package:flutter/material.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8B4C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ahmad Finance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Sapaan
            const Text(
              'Halo, Ahmad 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Kelola keuanganmu dengan lebih mudah.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // Saldo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F8B4C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Saldo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Rp 0',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pemasukan & Pengeluaran
            Row(
              children: [

                Expanded(
                  child: _summaryCard(
                    icon: Icons.arrow_downward,
                    title: 'Pemasukan',
                    amount: 'Rp 0',
                    iconColor: Colors.green,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _summaryCard(
                    icon: Icons.arrow_upward,
                    title: 'Pengeluaran',
                    amount: 'Rp 0',
                    iconColor: Colors.red,
                  ),
                ),

              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'Menu Keuangan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Menu
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [

                _menuCard(
                  icon: Icons.add_circle_outline,
                  title: 'Tambah Transaksi',
                  onTap: () {},
                ),

                _menuCard(
                  icon: Icons.receipt_long,
                  title: 'Transaksi',
                  onTap: () {},
                ),

                _menuCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Rekening',
                  onTap: () {},
                ),

                _menuCard(
                  icon: Icons.bar_chart,
                  title: 'Laporan',
                  onTap: () {},
                ),

              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'Transaksi Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [

                  Icon(
                    Icons.receipt_long_outlined,
                    size: 50,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Belum ada transaksi',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF0F8B4C),
        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),

        ],
      ),
    );
  }

  static Widget _summaryCard({
    required IconData icon,
    required String title,
    required String amount,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Icon(
            icon,
            color: iconColor,
          ),

          const SizedBox(height: 8),

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
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

        ],
      ),
    );
  }

  static Widget _menuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(
              icon,
              size: 35,
              color: const Color(0xFF0F8B4C),
            ),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

          ],
        ),
      ),
    );
  }
}