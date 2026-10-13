import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/complaint_model.dart';
import 'dart:async' show unawaited;

class OwnerComplaintDetailScreen extends StatefulWidget {
  final ComplaintModel complaint;
  const OwnerComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<OwnerComplaintDetailScreen> createState() =>
      _OwnerComplaintDetailScreenState();
}

class _OwnerComplaintDetailScreenState
    extends State<OwnerComplaintDetailScreen> {
  late ComplaintModel _complaint;
  final TextEditingController _noteController = TextEditingController();
  late ApiClient _apiClient;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
    _noteController.text = _complaint.adminNote ?? '';
    _apiClient = ApiClient();
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      final response = await _apiClient.dio.put(
        '/v1/complaints/${_complaint.id}/status',
        queryParameters: {'adminId': 1}, // Lấy User ID thật
        data: {'status': newStatus, 'adminNote': _noteController.text},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _complaint = ComplaintModel.fromJson(response.data['data']);
        });
        if (mounted) {
          ToastUtils.show(
            context,
            'Cập nhật trạng thái thành công!',
            isError: false,
          );
        }
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi cập nhật: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppTheme.kWarning;
      case 'PROCESSING':
        return AppTheme.kBrand;
      case 'RESOLVED':
        return AppTheme.kSuccess;
      case 'REJECTED':
        return AppTheme.kTextMuted;
      default:
        return AppTheme.kTextPrimary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'PROCESSING':
        return 'Đang xử lý';
      case 'RESOLVED':
        return 'Đã giải quyết';
      case 'REJECTED':
        return 'Từ chối';
      default:
        return status;
    }
  }

  void _showStatusBottomSheet() {
    final statuses = ['PENDING', 'PROCESSING', 'RESOLVED', 'REJECTED'];
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.kSurface1Light,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cập nhật trạng thái',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...statuses.map(
                (s) => ListTile(
                  title: Text(
                    _getStatusText(s),
                    style: TextStyle(
                      color: _getStatusColor(s),
                      fontWeight: _complaint.status == s
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: _complaint.status == s
                      ? Icon(
                          CupertinoIcons.checkmark_alt,
                          color: _getStatusColor(s),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (s != _complaint.status) unawaited(_updateStatus(s));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      appBar: AppBar(
        title: const Text('Chi tiết phản ánh'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Hero(
          tag: 'complaint_${_complaint.id}',
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.kSurface1Light,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _complaint.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        CupertinoIcons.person_solid,
                        'Người gửi',
                        '${_complaint.tenantName} (${_complaint.tenantPhone})',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        CupertinoIcons.home,
                        'Phòng',
                        _complaint.roomName ?? 'N/A',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        CupertinoIcons.tag_fill,
                        'Danh mục',
                        _complaint.category,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nội dung:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.kTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _complaint.description ?? 'Không có nội dung',
                        style: const TextStyle(color: AppTheme.kTextPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_complaint.images.isNotEmpty)
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.kSurface1Light,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hình ảnh đính kèm',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _complaint.images.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      _complaint.images[index],
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  color: AppTheme.kSurface1Light,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ghi chú xử lý (Nội bộ)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Nhập ghi chú hoặc kết quả xử lý...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: AppTheme.kBackgroundLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _isUpdating
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _showStatusBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getStatusColor(_complaint.status),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Text(
                    'Trạng thái hiện tại: ${_getStatusText(_complaint.status)} (Bấm để đổi)',
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.kTextSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppTheme.kTextSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.kTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
