import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  final String? initialMallId;

  const ReportsScreen({super.key, this.initialMallId});
  static const routeName = '/admin/reports';

  @override
  Widget build(BuildContext context) {
    // Mobile friendly cards + short filters
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.date_range),
                      hintText: 'Select date range',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: () {}, child: const Text('Apply')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: List.generate(6, (index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('Report ${index + 1}'),
                      subtitle: const Text('Summary of parking usage'),
                      trailing: IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {},
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
