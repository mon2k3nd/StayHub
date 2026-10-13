import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../network/api_client.dart';

/// Runtime diagnostic overlay that probes the configured backend and shows the
/// resolved base URL plus the exact result on screen.
///
/// Purpose: when the release APK cannot reach the backend (blank data, login
/// failure, "network error"), this banner makes the root cause visible without
/// needing `adb logcat`.
///
/// It uses `package:http` (NOT `dart:io`) so the SAME code runs on Android,
/// iOS and Web without `Unsupported operation: Platform._version` crashes.
///
/// It probes the SAME endpoint the guest feed uses
/// (`/v1/rooms/public/search?sortBy=newest`) so the result reflects reality.
/// The banner auto-hides on success and can be dismissed by the user.
class BackendConnectivityDiagnostic extends StatefulWidget {
  const BackendConnectivityDiagnostic({super.key});

  @override
  State<BackendConnectivityDiagnostic> createState() =>
      _BackendConnectivityDiagnosticState();
}

class _BackendConnectivityDiagnosticState
    extends State<BackendConnectivityDiagnostic> {
  String? _message;
  bool _isError = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Delay slightly so the first frame renders before the probe runs.
    WidgetsBinding.instance.addPostFrameCallback((_) => _probe());
  }

  Future<void> _probe() async {
    final baseUrl = ApiClient.baseUrl;
    debugPrint('[DIAG] Resolved API baseUrl = $baseUrl');

    // Probe the exact endpoint the guest feed uses.
    final uri = Uri.parse(
      '$baseUrl/v1/rooms/public/search?sortBy=newest&page=0&size=1',
    );

    try {
      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      debugPrint('[DIAG] HTTP ${response.statusCode} @ $uri');

      if (response.statusCode == 200) {
        // Parse item count so we can confirm real data is returned.
        int count = -1;
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final data = json['data'];
          if (data is Map && data['content'] is List) {
            count = (data['content'] as List).length;
          }
        } catch (_) {}

        if (!mounted) return;
        setState(() {
          _visible = true;
          _isError = false;
          _message =
              'Backend OK (HTTP 200).\nURL: $baseUrl\nSố phòng tải được: $count';
        });
        // Auto-hide the success banner after a few seconds.
        Timer(const Duration(seconds: 6), () {
          if (mounted) setState(() => _visible = false);
        });
      } else {
        final body = response.body;
        _fail(
          'Backend trả lỗi HTTP ${response.statusCode}.\n'
          'URL: $baseUrl\n'
          'Nội dung: ${body.length > 160 ? body.substring(0, 160) : body}',
        );
      }
    } on TimeoutException {
      _fail(
        'Backend không phản hồi (timeout).\n'
        'URL: $baseUrl\n'
        '→ Máy tính có thể bị firewall chặn hoặc tunnel đã ngừng chạy.',
      );
    } catch (e) {
      _fail(
        'Không kết nối được backend.\n'
        'URL: $baseUrl\n'
        'Lỗi: $e\n'
        '→ Thiết bị không tới được URL này (mạng/firewall/tunnel đã tắt).',
      );
    }
  }

  void _fail(String message) {
    debugPrint('[DIAG] FAILED: $message');
    if (!mounted) return;
    setState(() {
      _visible = true;
      _isError = true;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _message == null) return const SizedBox.shrink();

    final color = _isError ? const Color(0xFFB00020) : const Color(0xFF1B5E20);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isError
                      ? Icons.wifi_off_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _message!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _visible = false),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
