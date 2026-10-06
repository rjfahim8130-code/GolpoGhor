import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('আবিষ্কার'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.local_fire_department, color: AppColors.accent),
            title: const Text('ট্রেন্ডিং'),
            subtitle: const Text('সবচেয়ে বেশি পঠিত'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/trending'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'ক্যাটাগরি',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.categories.map((c) {
              return ActionChip(
                label: Text(c),
                onPressed: () => context.push(
                  Uri(path: '/category', queryParameters: {'name': c}).toString(),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('সার্চ'),
            onTap: () => context.push('/search'),
          ),
        ],
      ),
    );
  }
}
