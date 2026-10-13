import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AiCallSimulationScreen extends ConsumerStatefulWidget {
  const AiCallSimulationScreen({super.key});

  @override
  ConsumerState<AiCallSimulationScreen> createState() =>
      _AiCallSimulationScreenState();
}

class _AiCallSimulationScreenState extends ConsumerState<AiCallSimulationScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  Timer? _callTimer;
  int _seconds = 0;
  String _status = 'Đang khởi tạo kết nối...';
  String _transcript = '';
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _callSteps = [
    {
      'time': 2,
      'status': 'Đang đổ chuông tới Trần Văn A (Phòng 101)...',
      'text': null,
      'speaker': null,
    },
    {'time': 6, 'status': 'Khách đã bắt máy.', 'text': null, 'speaker': null},
    {
      'time': 7,
      'status': 'AI đang đàm thoại...',
      'text':
          'Dạ alo, xin chào. Đây có phải số máy của anh Trần Văn A không ạ?',
      'speaker': 'AI',
    },
    {
      'time': 10,
      'status': 'AI đang đàm thoại...',
      'text': 'Đúng rồi, ai đấy?',
      'speaker': 'Khách',
    },
    {
      'time': 12,
      'status': 'AI đang đàm thoại...',
      'text':
          'Dạ em là trợ lý ảo từ ban quản lý nhà trọ StayHub. Hiện tại phòng 101 của anh đang có hóa đơn 4,500,000đ đã quá hạn 5 ngày.',
      'speaker': 'AI',
    },
    {
      'time': 18,
      'status': 'AI đang đàm thoại...',
      'text': 'À anh quên mất. Để chiều đi làm về anh chuyển khoản nhé.',
      'speaker': 'Khách',
    },
    {
      'time': 22,
      'status': 'AI đang đàm thoại...',
      'text':
          'Dạ vâng, hệ thống đã ghi nhận lịch hẹn thanh toán của anh vào chiều nay. Cảm ơn anh A, chúc anh một ngày tốt lành!',
      'speaker': 'AI',
    },
    {
      'time': 27,
      'status': 'Cuộc gọi kết thúc thành công.',
      'text': null,
      'speaker': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    unawaited(_waveController.repeat(reverse: true));

    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _checkStep();
      });
      if (_seconds >= 30) {
        timer.cancel();
        _waveController.stop();
      }
    });
  }

  void _checkStep() {
    if (_currentStep < _callSteps.length) {
      final step = _callSteps[_currentStep];
      if (_seconds >= step['time']) {
        _status = step['status'];
        if (step['text'] != null) {
          final speaker = step['speaker'];
          final color = speaker == 'AI' ? '#4F46E5' : '#10B981';
          _transcript +=
              '<br><b style="color:$color">$speaker:</b> ${step['text']}';

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              unawaited(
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent + 100,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                ),
              );
            }
          });
        }
        _currentStep++;
        _checkStep(); // check if multiple steps happen in the same second
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _callTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kTextPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.kTextPrimary.withValues(alpha: 0.8),
        middle: const Text(
          'AI Live Call',
          style: TextStyle(color: CupertinoColors.white),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.clear, color: CupertinoColors.white),
          onPressed: () {
            _callTimer?.cancel();
            context.pop();
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildTargetInfo(),
            const SizedBox(height: 40),
            _buildWaveform(),
            const SizedBox(height: 20),
            Text(
              _formatTime(_seconds),
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              style: TextStyle(
                color: _seconds >= 27
                    ? CupertinoColors.systemGreen
                    : AppTheme.kTextSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(child: _buildTranscriptBox()),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetInfo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.kSurfaceBlue,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.kBrand, width: 3),
            image: const DecorationImage(
              image: NetworkImage('https://i.pravatar.cc/150?img=11'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Trần Văn A (Phòng 101)',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Số tiền nợ: 4,500,000đ',
          style: TextStyle(color: CupertinoColors.systemRed, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    final isTalking = _seconds >= 7 && _seconds < 27;
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(15, (index) {
          return AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final randomFactor = isTalking
                  ? Random().nextDouble() * 0.8 + 0.2
                  : 0.1;
              final height = isTalking
                  ? 20 +
                        40 *
                            randomFactor *
                            sin(_waveController.value * pi * 2 + index)
                  : 5.0;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 6,
                height: height.abs() + 5, // ensure positive
                decoration: BoxDecoration(
                  color: isTalking ? AppTheme.kBrand : AppTheme.kTextSecondary,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: isTalking
                      ? [
                          BoxShadow(
                            color: AppTheme.kBrand.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildTranscriptBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: ListView(
        controller: _scrollController,
        children: [
          const Text(
            'LIVE TRANSCRIPT',
            style: TextStyle(
              color: AppTheme.kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _parseHtml(_transcript),
        ],
      ),
    );
  }

  Widget _parseHtml(String text) {
    if (text.isEmpty) return const SizedBox();
    final parts = text.split('<br>');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.where((p) => p.isNotEmpty).map((p) {
        final isAI = p.contains('AI:');
        final content = p.replaceAll(RegExp(r'<[^>]*>'), '');
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: isAI ? 'AI: ' : 'Khách: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAI ? AppTheme.kBrand : CupertinoColors.systemGreen,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: content.replaceFirst(isAI ? 'AI: ' : 'Khách: ', ''),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {},
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: CupertinoColors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.mic_slash_fill,
              color: CupertinoColors.white,
            ),
          ),
        ),
        const SizedBox(width: 32),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            _callTimer?.cancel();
            context.pop();
          },
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemRed.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.phone_down_fill,
              color: CupertinoColors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 32),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {},
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: CupertinoColors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.speaker_2_fill,
              color: CupertinoColors.white,
            ),
          ),
        ),
      ],
    );
  }
}
