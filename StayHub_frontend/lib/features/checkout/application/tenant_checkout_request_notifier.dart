import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../contract/data/models/contract_model.dart';
import '../data/models/checkout_request_model.dart';
import 'checkout_provider.dart';
import 'dart:async' show unawaited;

part 'tenant_checkout_request_notifier.g.dart';

class CheckoutRequestState {
  final bool isLoading;
  final String? error;
  final CameraController? cameraController;
  final List<String>
  checklistItems; // e.g., ["Đồng hồ điện", "Đồng hồ nước", "Tình trạng phòng"]
  final Map<int, String>
  capturedImages; // Map of checklist item index to image path
  final List<String> beforeImages; // Parsed from contractImages
  final int currentItemIndex;

  CheckoutRequestState({
    this.isLoading = false,
    this.error,
    this.cameraController,
    this.checklistItems = const [
      "Đồng hồ điện",
      "Đồng hồ nước",
      "Hiện trạng phòng 1",
      "Hiện trạng phòng 2",
    ],
    this.capturedImages = const {},
    this.beforeImages = const [],
    this.currentItemIndex = 0,
  });

  CheckoutRequestState copyWith({
    bool? isLoading,
    String? error,
    CameraController? cameraController,
    List<String>? checklistItems,
    Map<int, String>? capturedImages,
    List<String>? beforeImages,
    int? currentItemIndex,
  }) {
    return CheckoutRequestState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      cameraController: cameraController ?? this.cameraController,
      checklistItems: checklistItems ?? this.checklistItems,
      capturedImages: capturedImages ?? this.capturedImages,
      beforeImages: beforeImages ?? this.beforeImages,
      currentItemIndex: currentItemIndex ?? this.currentItemIndex,
    );
  }

  bool get isAllCaptured => capturedImages.length == checklistItems.length;
}

@riverpod
class TenantCheckoutRequestNotifier extends _$TenantCheckoutRequestNotifier {
  @override
  CheckoutRequestState build(
    ContractModel contract,
    CheckoutRequestModel? previousRequest,
  ) {
    final initialState = _initData(contract, previousRequest);
    unawaited(_initCamera());

    // Dispose camera on destruction
    ref.onDispose(() {
      unawaited(state.cameraController?.dispose());
    });

    return initialState;
  }

  CheckoutRequestState _initData(
    ContractModel contract,
    CheckoutRequestModel? previousRequest,
  ) {
    List<String> beforeImgs = [];
    if (contract.contractImages != null) {
      try {
        final decoded = jsonDecode(contract.contractImages!);
        if (decoded is List) {
          beforeImgs = decoded.map((e) => e.toString()).toList();
        } else {
          beforeImgs = [contract.contractImages!];
        }
      } catch (e) {
        beforeImgs = [contract.contractImages!];
      }
    }

    // Fallback if not enough before images
    while (beforeImgs.length < 4) {
      beforeImgs.add("");
    }

    Map<int, String> initialCaptured = {};
    if (previousRequest != null &&
        previousRequest.status == 'REJECTED' &&
        previousRequest.checkoutImages != null) {
      try {
        final decoded = jsonDecode(previousRequest.checkoutImages!);
        if (decoded is List) {
          for (int i = 0; i < decoded.length; i++) {
            // Mock logic: keep some, let user retake others
            if (i % 2 == 0) {
              initialCaptured[i] = decoded[i].toString();
            }
          }
        }
      } catch (e) {
        // ignore
      }
    }

    return CheckoutRequestState(
      beforeImages: beforeImgs,
      capturedImages: initialCaptured,
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final controller = CameraController(
          cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await controller.initialize();
        state = state.copyWith(cameraController: controller);
      } else {
        state = state.copyWith(
          error:
              "Máy ảo không có Camera. Vui lòng chọn ảnh từ thư viện để tiếp tục.",
        );
      }
    } catch (e) {
      state = state.copyWith(
        error:
            "Máy ảo không có Camera. Vui lòng chọn ảnh từ thư viện để tiếp tục.",
      );
    }
  }

  Future<void> takePicture() async {
    if (state.cameraController == null ||
        !state.cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await state.cameraController!.takePicture();
      final newImages = Map<int, String>.from(state.capturedImages);
      newImages[state.currentItemIndex] = image.path;

      int nextIndex = state.currentItemIndex;
      if (newImages.length < state.checklistItems.length) {
        for (int i = 0; i < state.checklistItems.length; i++) {
          if (!newImages.containsKey(i)) {
            nextIndex = i;
            break;
          }
        }
      }

      state = state.copyWith(
        capturedImages: newImages,
        currentItemIndex: nextIndex,
      );
    } catch (e) {
      state = state.copyWith(error: "Lỗi chụp ảnh: $e");
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final newImages = Map<int, String>.from(state.capturedImages);
        newImages[state.currentItemIndex] = pickedFile.path;

        int nextIndex = state.currentItemIndex;
        if (newImages.length < state.checklistItems.length) {
          for (int i = 0; i < state.checklistItems.length; i++) {
            if (!newImages.containsKey(i)) {
              nextIndex = i;
              break;
            }
          }
        }

        state = state.copyWith(
          capturedImages: newImages,
          currentItemIndex: nextIndex,
        );
      }
    } catch (e) {
      state = state.copyWith(error: "Lỗi chọn ảnh: $e");
    }
  }

  Future<void> takePictureWithSystemCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final newImages = Map<int, String>.from(state.capturedImages);
        newImages[state.currentItemIndex] = pickedFile.path;

        int nextIndex = state.currentItemIndex;
        if (newImages.length < state.checklistItems.length) {
          for (int i = 0; i < state.checklistItems.length; i++) {
            if (!newImages.containsKey(i)) {
              nextIndex = i;
              break;
            }
          }
        }

        state = state.copyWith(
          capturedImages: newImages,
          currentItemIndex: nextIndex,
        );
      }
    } catch (e) {
      state = state.copyWith(error: "Lỗi chụp ảnh từ hệ thống: $e");
    }
  }

  void selectItem(int index) {
    state = state.copyWith(currentItemIndex: index);
  }

  Future<bool> submitRequest(Map<String, dynamic> data) async {
    if (!state.isAllCaptured) {
      state = state.copyWith(
        error: "Bạn phải chụp đầy đủ tất cả các mục tài sản.",
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: "");
    try {
      List<String> paths = [];
      for (int i = 0; i < state.checklistItems.length; i++) {
        paths.add(state.capturedImages[i]!);
      }

      await ref.read(checkoutRepositoryProvider).createRequest(data, paths);

      // Refresh the list
      ref.invalidate(tenantCheckoutRequestsProvider);
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      String msg = e.response?.data?['message'] ?? e.message ?? e.toString();
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
