import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/user_entity.dart';
import '../../../core/utils/toast_utils.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'widgets/smart_ocr_camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/components/responsive_file_image.dart';
import 'dart:async' show unawaited;

part 'ekyc_verification_state.dart';
part 'ekyc_verification_reverify_ui.dart';

class EkycVerificationScreen extends ConsumerStatefulWidget {
  final VoidCallback onVerificationComplete;

  const EkycVerificationScreen({
    super.key,
    required this.onVerificationComplete,
  });

  @override
  ConsumerState<EkycVerificationScreen> createState() =>
      _EkycVerificationScreenState();
}

class _InteractiveScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _InteractiveScale({required this.child, this.onTap});

  @override
  State<_InteractiveScale> createState() => _InteractiveScaleState();
}

class _InteractiveScaleState extends State<_InteractiveScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      onTap: () {
        if (widget.onTap != null) {
          unawaited(HapticFeedback.lightImpact());
          widget.onTap!();
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
