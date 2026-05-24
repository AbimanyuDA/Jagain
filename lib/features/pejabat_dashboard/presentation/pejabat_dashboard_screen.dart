import 'package:flutter/material.dart';

class PejabatDashboardScreen extends StatelessWidget {
  const PejabatDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pejabat - Jagain'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, Dinas Pekerjaan Umum',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('Wilayah Administrasi: Kota Bandung'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Laporan Wilayah Anda',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // List of regional reports
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text('Lubang Jalan Raya No. ${index + 1}'),
                      subtitle: const Text('Status: Dilaporkan'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          // Change Status flow
                        },
                        child: const Text('Proses'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
