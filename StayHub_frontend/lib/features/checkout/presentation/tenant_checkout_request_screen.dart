import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../contract/data/models/contract_model.dart';
import '../data/models/checkout_request_model.dart';
import '../application/tenant_checkout_request_notifier.dart';
import '../../../core/components/responsive_file_image.dart';
import 'dart:async' show unawaited;

class TenantCheckoutRequestScreen extends ConsumerStatefulWidget {
  final ContractModel contract;
  final CheckoutRequestModel? previousRequest;

  const TenantCheckoutRequestScreen({
    super.key,
    required this.contract,
    this.previousRequest,
  });

  @override
  ConsumerState<TenantCheckoutRequestScreen> createState() =>
      _TenantCheckoutRequestScreenState();
}

class _TenantCheckoutRequestScreenState
    extends ConsumerState<TenantCheckoutRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _targetDate;
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit(WidgetRef ref) async {
    if (_isSubmitting) return;

    // unawaited(Debug step 1)
    unawaited(
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: const Text('Đã nhận click Gửi Yêu Cầu!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng điền ghi chú!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final state = ref.read(
      tenantCheckoutRequestProvider(widget.contract, widget.previousRequest),
    );
    if (!state.isAllCaptured) {
      unawaited(
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Lỗi', style: TextStyle(color: Colors.red)),
            content: const Text(
              'Bắt buộc phải chụp/tải lên đủ 4 bức ảnh tài sản!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final notifier = ref.read(
      tenantCheckoutRequestProvider(
        widget.contract,
        widget.previousRequest,
      ).notifier,
    );

    try {
      final success = await notifier.submitRequest({
        'contractId': widget.contract.id,
        'targetCheckoutDate': DateFormat('yyyy-MM-dd').format(_targetDate!),
        'tenantNote': _noteController.text,
      });

      if (success && mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'Thành công',
              style: TextStyle(color: Colors.green),
            ),
            content: const Text('Đã gửi yêu cầu trả phòng thành công!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
        if (mounted) {
          context.go('/tenant');
        }
      }
      // Bỏ đoạn check finalState.error ở đây vì đã có ref.listen ở hàm build xử lý hiển thị lỗi,
      // giúp tránh việc hiện 2 thông báo lỗi cùng lúc!
    } catch (e) {
      if (mounted) {
        unawaited(
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(
                'Exception Crash!',
                style: TextStyle(color: Colors.red),
              ),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      tenantCheckoutRequestProvider(widget.contract, widget.previousRequest),
    );

    ref.listen(
      tenantCheckoutRequestProvider(widget.contract, widget.previousRequest),
      (previous, next) {
        if (next.error != null && next.error != previous?.error) {
          unawaited(
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Lỗi', style: TextStyle(color: Colors.red)),
                content: Text(next.error!),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: null,
        middle: const Text(
          'Bàn Giao & Trả Phòng',
          style: TextStyle(color: CupertinoColors.black),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.activeBlue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(child: _buildBody(state, context)),
    );
  }

  Widget _buildBody(dynamic state, BuildContext context) {
    if (widget.previousRequest != null) {
      if (widget.previousRequest!.status == 'PENDING') {
        return _buildStatusScreen(
          icon: Icons.hourglass_top,
          color: Colors.orange,
          title: 'Đang Chờ Phê Duyệt',
          message:
              'Yêu cầu trả phòng của bạn đã được gửi và đang chờ chủ nhà xác nhận. Vui lòng đợi thông báo mới nhất.',
        );
      }
      if (widget.previousRequest!.status == 'APPROVED') {
        return _buildStatusScreen(
          icon: Icons.check_circle_outline,
          color: Colors.green,
          title: 'Đã Phê Duyệt',
          message:
              'Chủ nhà đã phê duyệt yêu cầu trả phòng. Vui lòng kiểm tra Hóa Đơn Quyết Toán trong mục hợp đồng của bạn.',
        );
      }
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Warning Banner nếu bị REJECTED
          if (widget.previousRequest?.status == 'REJECTED')
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Yêu cầu trước đó bị từ chối!',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lý do từ chủ nhà: ${widget.previousRequest?.ownerReason ?? "Không có lý do"}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Vui lòng chụp lại các mục còn thiếu theo yêu cầu.',
                    style: TextStyle(
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          const Text(
            'THÔNG TIN CHUNG',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: Text(
              _targetDate == null
                  ? 'Chọn ngày dự kiến dọn đi'
                  : 'Ngày dọn: ${DateFormat('dd/MM/yyyy').format(_targetDate!)}',
            ),
            trailing: const Icon(Icons.calendar_today),
            tileColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
              );
              if (date != null) setState(() => _targetDate = date);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Ghi chú bàn giao (Bắt buộc)',
              hintText: 'Nhập ghi chú hoặc "Không có"',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Không được để trống. Hãy nhập "Không có" nếu không có ghi chú.';
              }
              return null;
            },
            maxLines: 2,
          ),

          const SizedBox(height: 24),
          const Text(
            'CHECKLIST TÀI SẢN (GHOST OVERLAY)',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          // Danh sách checklist
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.checklistItems.length,
              itemBuilder: (context, index) {
                final isSelected = index == state.currentItemIndex;
                final isCaptured = state.capturedImages.containsKey(index);
                return GestureDetector(
                  onTap: () => ref
                      .read(
                        tenantCheckoutRequestProvider(
                          widget.contract,
                          widget.previousRequest,
                        ).notifier,
                      )
                      .selectItem(index),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.kAccentColor
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isCaptured ? Colors.green.shade50 : Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCaptured ? Icons.check_circle : Icons.camera_alt,
                          color: isCaptured
                              ? Colors.green
                              : (isSelected
                                    ? AppTheme.kAccentColor
                                    : Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.checklistItems[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? AppTheme.kAccentColor
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Camera Area
          if (state.cameraController != null &&
              state.cameraController!.value.isInitialized)
            Container(
              height: 400,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Lớp dưới cùng: Camera Stream
                  CameraPreview(state.cameraController!),

                  // Lớp phủ (Ghost Overlay)
                  if (state.beforeImages.length > state.currentItemIndex &&
                      state.beforeImages[state.currentItemIndex].isNotEmpty)
                    IgnorePointer(
                      child: Opacity(
                        opacity: 0.5,
                        child: Image.network(
                          state.beforeImages[state.currentItemIndex].startsWith(
                                'http',
                              )
                              ? state.beforeImages[state.currentItemIndex]
                              : '${ApiClient.baseUrl}${state.beforeImages[state.currentItemIndex]}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      ),
                    ),

                  // Nếu mục này đã chụp, hiển thị ảnh đã chụp đè lên
                  if (state.capturedImages.containsKey(state.currentItemIndex))
                    Positioned.fill(
                      child: Container(
                        color: Colors.black87,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ResponsiveFileImage(
                              File(
                                state.capturedImages[state.currentItemIndex]!,
                              ),
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () {
                                  // Xử lý xóa
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Nút chụp (nằm ở lớp trên cùng để nhận tap event)
                  if (!state.capturedImages.containsKey(state.currentItemIndex))
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => ref
                              .read(
                                tenantCheckoutRequestProvider(
                                  widget.contract,
                                  widget.previousRequest,
                                ).notifier,
                              )
                              .takePicture(),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            child: Center(
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else if (state.error != null && state.cameraController == null)
            Container(
              height: 400,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade200,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.error!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref
                            .read(
                              tenantCheckoutRequestProvider(
                                widget.contract,
                                widget.previousRequest,
                              ).notifier,
                            )
                            .pickImageFromGallery(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.blue),
                        ),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Chọn ảnh từ thư viện'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => ref
                            .read(
                              tenantCheckoutRequestProvider(
                                widget.contract,
                                widget.previousRequest,
                              ).notifier,
                            )
                            .takePictureWithSystemCamera(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.kAccentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Chụp ảnh bằng Camera máy'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '(Hãy lặp lại bước chọn ảnh cho đến khi đủ 4 bức ảnh ở Checklist phía trên nhé)',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            const SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator()),
            ),

          const SizedBox(height: 32),

          // Nút Gửi Bàn Giao
          ElevatedButton(
            onPressed: state.isLoading ? null : () => _submit(ref),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: state.isAllCaptured
                  ? AppTheme.kAccentColor
                  : Colors.grey,
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: state.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Gửi Yêu Cầu Trả Phòng',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusScreen({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kAccentColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text(
              'Quay Về Trang Chủ',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
