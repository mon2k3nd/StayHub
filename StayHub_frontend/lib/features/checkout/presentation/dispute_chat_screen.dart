import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_notifier.dart';
import '../../bill/data/models/bill_model.dart';
import '../../bill/application/bill_notifier.dart';
import '../application/dispute_chat_provider.dart';
import 'dart:async' show unawaited;

class DisputeChatScreen extends ConsumerStatefulWidget {
  final BillModel initialBill;
  final bool isOwner;

  const DisputeChatScreen({
    super.key,
    required this.initialBill,
    required this.isOwner,
  });

  @override
  ConsumerState<DisputeChatScreen> createState() => _DisputeChatScreenState();
}

class _DisputeChatScreenState extends ConsumerState<DisputeChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Trạng thái hóa đơn hiện tại trong bộ nhớ (cập nhật qua SSE)
  double _currentTotal = 0;
  double _currentDamageFee = 0;
  String _currentDamageReason = '';
  String _currentStatus = '';
  late ConfettiController _confettiController;
  bool _isSuccess = false;

  // Form sửa nhanh hóa đơn
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _damageFeeController;
  late TextEditingController _damageReasonController;

  @override
  void initState() {
    super.initState();
    _currentTotal = widget.initialBill.totalAmount ?? 0;
    _currentDamageFee = widget.initialBill.damageFee ?? 0;
    _currentDamageReason = widget.initialBill.damageReason ?? '';
    _currentStatus = widget.initialBill.status;
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _damageFeeController = TextEditingController(
      text: _currentDamageFee.toString(),
    );
    _damageReasonController = TextEditingController(text: _currentDamageReason);
  }

  /// BUGFIX (data): coerce an toàn sang double — tránh `as num` ném TypeError
  /// khi backend serialize BigDecimal thành String.
  double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _damageFeeController.dispose();
    _damageReasonController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authProvider).value;
    if (user == null) return;

    unawaited(
      ref
          .read(disputeChatProvider(widget.initialBill.id).notifier)
          .sendMessage(user.id.toString(), text),
    );
    _messageController.clear();
    _scrollToBottom();
  }

  void _showQuickFixBottomSheet() {
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sửa Nhanh Hóa Đơn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _damageFeeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền phạt mới (đ)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Vui lòng nhập tiền phạt';
                      }
                      final num = double.tryParse(val);
                      if (num == null || num < 0) return 'Số tiền không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ràng buộc siêu chặt chẽ
                  TextFormField(
                    controller: _damageReasonController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Lý do điều chỉnh (Bắt buộc)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      final num =
                          double.tryParse(_damageFeeController.text) ?? 0;
                      if (num > 0) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Bắt buộc phải nhập lý do điều chỉnh!';
                        }
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final newFee =
                              double.tryParse(_damageFeeController.text) ?? 0;
                          final newReason = _damageReasonController.text;

                          // Tính lại tổng
                          final baseTotal =
                              (widget.initialBill.rentAmount ?? 0) +
                              (widget.initialBill.serviceAmount ?? 0) +
                              (widget.initialBill.electricAmount ?? 0) +
                              (widget.initialBill.waterAmount ?? 0);

                          final payload = {
                            'damageFee': newFee,
                            'damageReason': newReason,
                            'totalAmount': baseTotal + newFee,
                          };

                          unawaited(
                            ref
                                .read(
                                  disputeChatProvider(
                                    widget.initialBill.id,
                                  ).notifier,
                                )
                                .updateBill(payload),
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.kAccentColor,
                      ),
                      child: const Text(
                        'Xác nhận Cập nhật',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(disputeChatProvider(widget.initialBill.id));
    final user = ref.watch(authProvider).value;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Cập nhật lại UI Hóa đơn nếu có tin nhắn hệ thống (BILL_UPDATED)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.isNotEmpty) {
        final lastMsg = messages.last;
        if (lastMsg['type'] == 'system' &&
            lastMsg['event'] == 'PAYMENT_SUCCESS' &&
            !_isSuccess) {
          _isSuccess = true;
          _confettiController.play();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Thanh toán thành công! Trả phòng hoàn tất!'),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.of(this.context).popUntil((route) => route.isFirst);
            }
          });
        } else if (lastMsg['type'] == 'system' && lastMsg['data'] != null) {
          final updatedData = lastMsg['data'];
          if (updatedData['totalAmount'] != null &&
              updatedData['totalAmount'] != _currentTotal) {
            setState(() {
              // BUGFIX (data): trước đây ép `as num` — nếu backend trả
              // String (BigDecimal serialize) thì ném TypeError. Coerce an toàn.
              _currentTotal = _num(updatedData['totalAmount']);
              _currentDamageFee = _num(updatedData['damageFee']);
              _currentDamageReason = updatedData['damageReason'] ?? '';
            });
          }
          if (updatedData['status'] != null &&
              updatedData['status'] != _currentStatus) {
            setState(() {
              _currentStatus = updatedData['status'];
            });
          }
        }
        _scrollToBottom();
      }
    });

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Thương Lượng Hóa Đơn'),
            actions: [
              if (widget.isOwner)
                IconButton(
                  icon: const Icon(Icons.edit_document),
                  tooltip: 'Sửa nhanh hóa đơn',
                  onPressed: _showQuickFixBottomSheet,
                ),
            ],
          ),
          body: Column(
            children: [
              // STICKY BILL CARD (Real-time update)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, AppTheme.kAccentColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TỔNG THANH TOÁN',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: _currentTotal),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Text(
                          formatter.format(value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tiền phạt: ${formatter.format(_currentDamageFee)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Lý do: $_currentDamageReason',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (_currentStatus == 'PENDING_CASH') ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orangeAccent),
                        ),
                        child: widget.isOwner
                            ? Column(
                                children: [
                                  const Text(
                                    'Khách báo đã trả tiền mặt',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      unawaited(
                                        ref
                                            .read(billProvider.notifier)
                                            .confirmCashPayment(
                                              widget.initialBill.id,
                                            ),
                                      );
                                      // Local optimistic update
                                      setState(() => _currentStatus = 'PAID');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.green,
                                    ),
                                    child: const Text(
                                      'XÁC NHẬN ĐÃ THU TIỀN MẶT',
                                    ),
                                  ),
                                ],
                              )
                            : const Center(
                                child: Text(
                                  'Đang chờ chủ nhà xác nhận thu tiền mặt...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ] else if (!widget.isOwner && _currentStatus != 'PAID') ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                unawaited(
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Thanh Toán Online'),
                                      content: const Text(
                                        'Bạn có muốn giả lập thanh toán chuyển khoản thành công không?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Hủy'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            unawaited(
                                              ref
                                                  .read(billProvider.notifier)
                                                  .payBillOnline(
                                                    widget.initialBill.id,
                                                  ),
                                            );
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text('Xác nhận'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.kAccentColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text(
                                'CHUYỂN KHOẢN',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                unawaited(
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Thanh Toán'),
                                      content: const Text(
                                        'Bạn xác nhận đã thanh toán bằng tiền mặt cho Chủ nhà?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Hủy'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            unawaited(
                                              ref
                                                  .read(billProvider.notifier)
                                                  .payBill(
                                                    widget.initialBill.id,
                                                    cash: true,
                                                  ),
                                            );
                                            // Local optimistic update
                                            setState(
                                              () => _currentStatus =
                                                  'PENDING_CASH',
                                            );
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text('Xác nhận'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.kAccentColor,
                              ),
                              child: const Text(
                                'TIỀN MẶT',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // CHAT MESSAGES
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    if (msg['type'] == 'system') {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            msg['message'],
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }

                    final isMe = msg['senderId'] == user?.id.toString();
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppTheme.kAccentColor
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(0) : null,
                            bottomLeft: !isMe ? const Radius.circular(0) : null,
                          ),
                        ),
                        child: Text(
                          msg['message'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // CHAT INPUT
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn thương lượng...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppTheme.kAccentColor,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3.14 / 2, // fall down
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
          ),
        ),
      ],
    );
  }
}
