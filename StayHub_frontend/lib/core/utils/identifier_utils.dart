/// Hệ thống Định Danh 3 Tầng (3-Layer Hierarchical Identifier System)
///
/// Quy tắc:
///   Owner  : {CCCD}                              → 001099000888
///   Branch : {CCCD}-{BRANCH_CODE}                → 001099000888-XUANTHUY
///   Room   : {CCCD}-{BRANCH_CODE}-{ROOM_NAME}    → 001099000888-XUANTHUY-101
///
/// Separator bắt buộc: `-`
/// Branch code / Room name: chỉ [A-Z0-9_], max 20 ký tự, tự động UPPERCASE.
class IdentifierUtils {
  IdentifierUtils._(); // Không cho khởi tạo instance

  static const String _separator = '-';
  static const int _cccdLength = 12;
  static const int _maxCodeLength = 20;

  // ────────────────────────────────────────────────────────────────
  // AUTO-GENERATE FROM NAME
  // ────────────────────────────────────────────────────────────────

  /// Bộ bảng chuyển đổi tiếng Việt có dấu → không dấu
  static final Map<String, String> _vietMap = {
    'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    'đ': 'd',
    // Chữ hoa
    'À': 'A', 'Á': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A',
    'Ă': 'A', 'Ắ': 'A', 'Ằ': 'A', 'Ẳ': 'A', 'Ẵ': 'A', 'Ặ': 'A',
    'Â': 'A', 'Ấ': 'A', 'Ầ': 'A', 'Ẩ': 'A', 'Ẫ': 'A', 'Ậ': 'A',
    'È': 'E', 'É': 'E', 'Ẻ': 'E', 'Ẽ': 'E', 'Ẹ': 'E',
    'Ê': 'E', 'Ế': 'E', 'Ề': 'E', 'Ể': 'E', 'Ễ': 'E', 'Ệ': 'E',
    'Ì': 'I', 'Í': 'I', 'Ỉ': 'I', 'Ĩ': 'I', 'Ị': 'I',
    'Ò': 'O', 'Ó': 'O', 'Ỏ': 'O', 'Õ': 'O', 'Ọ': 'O',
    'Ô': 'O', 'Ố': 'O', 'Ồ': 'O', 'Ổ': 'O', 'Ỗ': 'O', 'Ộ': 'O',
    'Ơ': 'O', 'Ớ': 'O', 'Ờ': 'O', 'Ở': 'O', 'Ỡ': 'O', 'Ợ': 'O',
    'Ù': 'U', 'Ú': 'U', 'Ủ': 'U', 'Ũ': 'U', 'Ụ': 'U',
    'Ư': 'U', 'Ứ': 'U', 'Ừ': 'U', 'Ử': 'U', 'Ữ': 'U', 'Ự': 'U',
    'Ỳ': 'Y', 'Ý': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y', 'Ỵ': 'Y',
    'Đ': 'D',
  };

  /// Bỏ dấu tiếng Việt
  static String removeVietnameseAccents(String input) {
    String result = input;
    _vietMap.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }

  /// Tự động sinh Branch Code từ tên dãy trọ:
  /// "262 Xuân Thủy" → "262XUANTHUY"
  /// Bỏ dấu + bỏ khoảng trắng + bỏ ký tự đặc biệt + UPPERCASE
  ///
  /// QUAN TRỌNG — chống trùng mã:
  /// Trước đây hàm này CẮT CỤT chuỗi về 20 ký tự. Với tên dài, hai chi nhánh
  /// khác nhau nhưng có chung 16 ký tự đầu sẽ sinh ra CÙNG một mã
  /// (ví dụ "351 Cầu Giấy" và "351 Cầu Giấy 2" đều thành "H5_351CAUGIAY").
  /// Nay ta giữ nguyên phần đầu (prefix) và thay phần bị cắt bằng một HASH
  /// ngắn 6 ký tự sinh từ TOÀN BỘ chuỗi gốc. Nhờ vậy:
  ///   - Tên ngắn: giữ nguyên như cũ (không đổi hành vi cũ).
  ///   - Tên dài : prefix + "_" + hash → gần như không bao giờ trùng.
  /// Hash là deterministic nên cùng tên luôn ra cùng mã (idempotent).
  static String generateBranchCodeFromName(String branchName, {int? hostId}) {
    final noAccent = removeVietnameseAccents(branchName);
    final baseCode = noAccent
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '') // Chỉ giữ chữ và số
        .trim();

    // Tiền tố chủ nhà (nếu có) để tách mã giữa các chủ nhà khác nhau.
    final prefix = hostId != null ? 'H${hostId}_' : '';

    // Nếu vừa đủ 20 ký tự thì trả về luôn (giữ nguyên hành vi cũ).
    if (prefix.length + baseCode.length <= _maxCodeLength) {
      return '$prefix$baseCode';
    }

    // Tên quá dài → giữ prefix + phần đầu, phần đuôi thay bằng hash 6 ký tự.
    const int hashLen = 6;
    final int keepLen =
        _maxCodeLength - prefix.length - hashLen - 1; // -1 cho dấu '_'
    final String head = baseCode.substring(
      0,
      keepLen.clamp(1, baseCode.length),
    );
    final String hash = _shortHash(baseCode);
    return '$prefix${head}_$hash';
  }

  /// Sinh hash ngắn (6 ký tự [A-Z0-9]) từ chuỗi đầu vào.
  /// Dùng FNV-1a 32-bit — nhanh, deterministic, không cần thư viện ngoài.
  static String _shortHash(String input) {
    int hash = 0x811c9dc5; // FNV offset basis
    for (final int unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime, giữ 32-bit
    }
    // Chuyển sang base36 (0-9A-Z), pad '0' cho đủ 6 ký tự rồi lấy 6 ký tự cuối.
    final String encoded = hash.toRadixString(36).toUpperCase();
    final String padded = encoded.padLeft(6, '0');
    return padded.substring(padded.length - 6);
  }

  // ────────────────────────────────────────────────────────────────
  // SANITIZE
  // ────────────────────────────────────────────────────────────────

  /// Chuẩn hoá chuỗi input:
  /// - Trim whitespace hai đầu
  /// - UPPERCASE
  /// - Thay khoảng trắng bằng `_`
  /// - Xoá các ký tự không hợp lệ (chỉ giữ A-Z, 0-9, _)
  static String sanitize(String input) {
    return input
        .trim()
        .toUpperCase()
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^A-Z0-9_]'), '');
  }

  // ────────────────────────────────────────────────────────────────
  // VALIDATE
  // ────────────────────────────────────────────────────────────────

  /// Kiểm tra CCCD hợp lệ: đúng 12 chữ số.
  static bool isValidCccd(String cccd) {
    return RegExp(r'^\d{12}$').hasMatch(cccd.trim());
  }

  /// Kiểm tra Branch Code hợp lệ: [A-Z0-9_], không rỗng, tối đa 20 ký tự.
  static bool isValidBranchCode(String code) {
    final sanitized = sanitize(code);
    return sanitized.isNotEmpty &&
        sanitized.length <= _maxCodeLength &&
        RegExp(r'^[A-Z0-9_]+$').hasMatch(sanitized);
  }

  /// Kiểm tra Room Name hợp lệ: [A-Z0-9], không rỗng, tối đa 20 ký tự.
  /// (Không cho phép dấu gạch dưới ở room name để tránh lẫn với branch code)
  static bool isValidRoomName(String name) {
    final sanitized = sanitize(name).replaceAll('_', '');
    return sanitized.isNotEmpty &&
        sanitized.length <= _maxCodeLength &&
        RegExp(r'^[A-Z0-9]+$').hasMatch(sanitized);
  }

  // ────────────────────────────────────────────────────────────────
  // BUILD COMPOSITE IDs
  // ────────────────────────────────────────────────────────────────

  /// Tạo mã đầy đủ cho Branch:
  /// `{CCCD chủ nhà}-{Branch Code}`
  /// VD: `001099000888-XUANTHUY`
  static String buildBranchFullCode({
    required String ownerCccd,
    required String branchCode,
  }) {
    final cleanCode = sanitize(branchCode);
    return '${ownerCccd.trim()}$_separator$cleanCode';
  }

  /// Tạo mã đầy đủ cho Room:
  /// `{Branch Full Code}-{Room Name}`
  /// VD: `001099000888-XUANTHUY-101`
  static String buildRoomFullCode({
    required String branchFullCode,
    required String roomName,
  }) {
    final cleanName = sanitize(roomName).replaceAll('_', '');
    return '$branchFullCode$_separator$cleanName';
  }

  /// Tạo mã đầy đủ cho Room từ các thành phần riêng lẻ:
  static String buildRoomFullCodeFromParts({
    required String ownerCccd,
    required String branchCode,
    required String roomName,
  }) {
    final branchFull = buildBranchFullCode(
      ownerCccd: ownerCccd,
      branchCode: branchCode,
    );
    return buildRoomFullCode(branchFullCode: branchFull, roomName: roomName);
  }

  // ────────────────────────────────────────────────────────────────
  // FALLBACK (cho dữ liệu cũ không có branchCode)
  // ────────────────────────────────────────────────────────────────

  /// Tạo mã tạm thời cho dãy trọ cũ chưa có branchCode.
  /// VD: branchId = 12 → `BRANCH_12`
  static String generateFallbackBranchCode(int branchId) {
    return 'BRANCH_$branchId';
  }

  /// Lấy branchCode hiệu dụng: nếu null thì dùng fallback.
  static String effectiveBranchCode({
    required int branchId,
    required String? branchCode,
  }) {
    if (branchCode != null && branchCode.isNotEmpty) return branchCode;
    return generateFallbackBranchCode(branchId);
  }

  // ────────────────────────────────────────────────────────────────
  // PARSE (tách ngược)
  // ────────────────────────────────────────────────────────────────

  /// Tách mã Room đầy đủ ra các phần:
  /// `001099000888-XUANTHUY-101` → {owner: '001099000888', branch: 'XUANTHUY', room: '101'}
  static Map<String, String>? parseRoomFullCode(String fullCode) {
    final parts = fullCode.split(_separator);
    if (parts.length < 3) return null;
    return {
      'owner': parts[0],
      'branch': parts[1],
      'room': parts.sublist(2).join(_separator), // phòng có thể có thêm ký tự
    };
  }

  /// Tách mã Branch đầy đủ ra các phần:
  /// `001099000888-XUANTHUY` → {owner: '001099000888', branch: 'XUANTHUY'}
  static Map<String, String>? parseBranchFullCode(String fullCode) {
    final parts = fullCode.split(_separator);
    if (parts.length < 2) return null;
    return {'owner': parts[0], 'branch': parts.sublist(1).join(_separator)};
  }

  // ────────────────────────────────────────────────────────────────
  // ERROR MESSAGES
  // ────────────────────────────────────────────────────────────────

  static String branchCodeError(String code) {
    final s = sanitize(code);
    if (s.isEmpty) return 'Mã dãy trọ không được để trống.';
    if (s.length > _maxCodeLength) {
      return 'Mã dãy trọ tối đa $_maxCodeLength ký tự.';
    }
    return 'Mã dãy trọ chỉ được dùng CHỮ HOA (A-Z), số (0-9) và dấu _ (gạch dưới).';
  }

  static String roomNameError(String name) {
    final s = sanitize(name).replaceAll('_', '');
    if (s.isEmpty) return 'Tên phòng không được để trống.';
    if (s.length > _maxCodeLength) {
      return 'Tên phòng tối đa $_maxCodeLength ký tự.';
    }
    return 'Tên phòng chỉ được dùng CHỮ và SỐ (A-Z, 0-9), không có ký tự đặc biệt.';
  }

  static const int cccdLength = _cccdLength;
  static const int maxCodeLength = _maxCodeLength;
}
