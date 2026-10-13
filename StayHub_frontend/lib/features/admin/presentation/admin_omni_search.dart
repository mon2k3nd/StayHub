import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;

import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/network/api_client.dart';
import 'admin_user_detail_screen.dart';

class AdminOmniSearchScreen extends StatefulWidget {
  const AdminOmniSearchScreen({super.key});

  @override
  State<AdminOmniSearchScreen> createState() => _AdminOmniSearchScreenState();
}

class _AdminOmniSearchScreenState extends State<AdminOmniSearchScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _results = [];

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Temporarily bypass token in this UI for demo or ensure token is passed
      // using the app's standard apiClient.
      final res = await ApiClient().dio.get(
        '/v1/admin/omni-search',
        queryParameters: {'query': query},
      );
      if (!mounted) return;
      if (res.data['success'] == true) {
        setState(() {
          _results = res.data['data'];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      // Ignore errors silently for now or show snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLightGray,
      navigationBar: CupertinoNavigationBar(
        middle: CupertinoSearchTextField(
          controller: _searchCtrl,
          placeholder: 'Tìm SĐT, Tên Chủ Trọ, Khách...',
          onChanged: (q) => _performSearch(q),
          autofocus: true,
          style: const TextStyle(color: CupertinoColors.black),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: _isSearching
            ? const Center(child: CupertinoActivityIndicator())
            : _results.isEmpty && _searchCtrl.text.isNotEmpty
            ? const Center(
                child: Text(
                  'Không tìm thấy kết quả nào.',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              )
            : _results.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 64,
                      color: CupertinoColors.systemGrey.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nhập từ khóa để bắt đầu quét CSDL',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  final isOwner = user['role'] == 'OWNER';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        unawaited(
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) =>
                                  AdminUserDetailScreen(userId: user['id']),
                            ),
                          ),
                        );
                      },
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isOwner
                                  ? LiquidGlassColors.adminAccent
                                  : LiquidGlassColors.staffAccent,
                              child: const Icon(
                                CupertinoIcons.person_fill,
                                color: CupertinoColors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? 'Không rõ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${user['phone']} • ${user['role']}',
                                    style: const TextStyle(
                                      color: CupertinoColors.systemGrey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOwner)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.activeOrange
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user['packageId'] ?? 'FREE',
                                  style: const TextStyle(
                                    color: CupertinoColors.activeOrange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            else if (user['cccd'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.activeBlue.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'CCCD: ${user['cccd']}',
                                  style: const TextStyle(
                                    color: CupertinoColors.activeBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
