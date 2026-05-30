import 'package:flutter/material.dart';

class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Picker Stub
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Ambil Foto Kerusakan'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Deskripsi Kerusakan',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            // Map Location Stub
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text('Pilih Lokasi Kerusakan'),
              subtitle: const Text('Tekan untuk memetakan koordinat'),
              trailing: const Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () {
                // Open Map Picker
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Submit Report logic
              },
              child: const Text('Kirim Laporan'),
            ),
          ],
        ),
      ),
    );
  }
}
