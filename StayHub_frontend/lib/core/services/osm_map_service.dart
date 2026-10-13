import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../data/address_data.dart';
import 'address_mapping_service.dart';

/// Ket qua reverse geocoding chuan hoa
class OsmAddress {
  final String? province;
  final String? district;
  final String? ward;
  final String? street;
  final String? houseNumber;
  final String displayAddress;

  const OsmAddress({
    this.province,
    this.district,
    this.ward,
    this.street,
    this.houseNumber,
    required this.displayAddress,
  });
}

/// Goi y dia chi tu autocomplete
class OsmSuggestion {
  final String displayName;
  final String shortName;
  final LatLng latLng;

  const OsmSuggestion({
    required this.displayName,
    required this.shortName,
    required this.latLng,
  });
}

/// Mô hình địa điểm chuẩn hóa nội bộ phục vụ gợi ý tức thì (0ms)
class _VnPlaceEntry {
  final String name;
  final String ward;
  final String district;
  final String city;
  final LatLng latLng;
  final List<String> aliases;
  final bool isStreet;

  const _VnPlaceEntry({
    required this.name,
    this.ward = '',
    required this.district,
    this.city = 'Hà Nội',
    required this.latLng,
    this.aliases = const [],
    this.isStreet = true,
  });

  String get fullDisplayName {
    final parts = <String>[];
    if (name.isNotEmpty) parts.add(name);
    if (ward.isNotEmpty && !name.contains(ward)) parts.add('Phường $ward');
    if (district.isNotEmpty && !name.contains(district)) {
      parts.add('Quận $district');
    }
    if (city.isNotEmpty && !name.contains(city)) parts.add(city);
    return parts.join(', ');
  }
}

/// Service tap trung xu ly moi nghiep vu ban do OSM.
/// Su dung OpenStreetMap Nominatim (mien phi, khong can API key).
class OsmMapService {
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';
  static const String _photonBase = 'https://photon.komoot.io'; // Fallback API
  static const Map<String, String> _headers = {
    'User-Agent': 'StayHubApp/1.0 (stayhub.app)',
    'Accept-Language': 'vi-VN,vi;q=0.9',
  };

  // Map Tiles (Google Maps Raster Tiles - sắc nét, chuẩn tiếng Việt, 0 watermark, tải cực nhanh)
  static const String tileUrl =
      'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
  static const List<String> tileSubdomains = ['0', '1', '2', '3'];

  // ─── PROVINCE NORMALIZER ─────────────────────────────────────────────────
  /// OSM now returns new merged province names (e.g. "Ninh Bình" covers old
  /// Hà Nam + Nam Định + Ninh Bình). This helper maps a (possibly new) province
  /// name back to the correct OLD 63-province name by looking up the district
  /// name in the old data, returning the province that contains that district.
  ///
  /// falls back to [rawProvince] if no mapping is found.
  static String resolveOld63Province(
    String rawProvince,
    String districtHint, {
    String? provinceHint,
  }) {
    if (rawProvince.isEmpty) return rawProvince;

    final normProv = AddressMappingService.normalizeString(rawProvince);

    // Check if OSM returned a NEW province name by seeing if it matches any
    // new-34 province. If not → it’s already an old name, return as-is.
    final new34Match = AddressData.provinces34.where((p) {
      final n = AddressMappingService.normalizeString(
        p['name'] as String? ?? '',
      );
      final d = AddressMappingService.normalizeString(
        p['display'] as String? ?? '',
      );
      return normProv == n ||
          normProv == d ||
          d.contains(normProv) ||
          normProv.contains(n);
    }).toList();

    if (new34Match.isEmpty) return rawProvince; // Already old-63 name

    // If we have a province hint from the UI, check if it belongs to this merged province.
    if (provinceHint != null && provinceHint.isNotEmpty) {
      final hintNorm = AddressMappingService.normalizeString(provinceHint);
      final oldProv = AddressData.getProvinces63Sorted().firstWhere(
        (p) =>
            AddressMappingService.normalizeString(p['name'] as String? ?? '') ==
            hintNorm,
        orElse: () => <String, dynamic>{},
      );
      if (oldProv.isNotEmpty) {
        final esgooIds = List<String>.from(
          new34Match.first['esgoo_ids'] as List? ?? [],
        );
        if (esgooIds.contains(oldProv['id'])) {
          return oldProv['name'] as String;
        }
      }
    }

    // We have a new province match. Use the district hint to pick the right
    // old-63 province from the set of esgoo_ids under this new province.
    if (districtHint.isNotEmpty) {
      final normDist = AddressMappingService.normalizeString(districtHint);
      // District-to-old-province lookup table (built from address_data.dart esgoo_ids)
      // We use a lightweight check: strip prefixes and compare.
      // Each new34 province's esgoo_ids covers multiple old provinces.
      final esgooIds = List<String>.from(
        new34Match.first['esgoo_ids'] as List? ?? [],
      );
      for (final eId in esgooIds) {
        // Look up the old-63 province name from _provinces63Raw via esgoo id
        final old63 = AddressData.getProvinces63Sorted().firstWhere(
          (p) => p['id'] == eId,
          orElse: () => <String, dynamic>{},
        );
        if (old63.isEmpty) continue;
        final oldName63 = AddressMappingService.normalizeString(
          old63['name'] as String? ?? '',
        );
        // Simple heuristic: if the district name contains part of the province
        // name (e.g. "Giao Thuy" doesn’t contain "Nam Dinh"), we can’t tell
        // from name alone — but we can at least prefer the one that matches
        // a partial city/province substring in the district string.
        if (normDist.contains(oldName63) || oldName63.contains(normDist)) {
          return old63['name'] as String;
        }
      }
    }

    // Cannot resolve via district — return the raw province string so callers
    // can fall back to their own district-anchored logic.
    return rawProvince;
  }

  /// Kiểm tra ký tự lạ không thuộc bảng chữ cái tiếng Việt (Thái, Lào, Khmer, CJK...)
  static bool hasNonVietnameseScript(String text) {
    return RegExp(
      r'[\u0E00-\u0E7F\u0E80-\u0EFF\u1780-\u17FF\u4E00-\u9FFF]',
    ).hasMatch(text);
  }

  /// Kiểm tra toạ độ có nằm hoàn toàn trong lãnh thổ và vùng biển Việt Nam hay không.
  /// Ngăn chặn việc lọt toạ độ từ Thái Lan, Lào, Campuchia.
  static bool isInsideVietnam(LatLng pt) {
    if (pt.latitude < 8.15 ||
        pt.latitude > 23.45 ||
        pt.longitude < 102.10 ||
        pt.longitude > 117.50) {
      return false;
    }
    // Dải miền Trung (13°N - 18.5°N): Phía Tây kinh độ 105.4°E thuộc Thái Lan (Yasothon, Roi Et...) và Lào
    if (pt.latitude >= 13.0 && pt.latitude <= 18.5 && pt.longitude < 105.40) {
      return false;
    }
    // Dải miền Nam (10.5°N - 12.0°N): Phía Tây 104.4°E thuộc Campuchia
    if (pt.latitude >= 10.5 && pt.latitude <= 12.0 && pt.longitude < 104.40) {
      return false;
    }
    return true;
  }

  /// Danh sách gợi ý nhanh các địa điểm phổ biến tại Việt Nam khi ấn vào ô tìm kiếm
  static List<OsmSuggestion> getQuickLocations() {
    return const [
      OsmSuggestion(
        shortName: '42 Phố Vĩnh Phúc',
        displayName: '42 Phố Vĩnh Phúc, Ba Đình, Hà Nội',
        latLng: LatLng(21.0425, 105.8115),
      ),
      OsmSuggestion(
        shortName: 'Phố Vĩnh Phúc',
        displayName: 'Phố Vĩnh Phúc, Ba Đình, Hà Nội',
        latLng: LatLng(21.0425, 105.8115),
      ),
      OsmSuggestion(
        shortName: 'Phố Đội Cấn',
        displayName: 'Phố Đội Cấn, Ba Đình, Hà Nội',
        latLng: LatLng(21.0360, 105.8200),
      ),
      OsmSuggestion(
        shortName: 'Đại học Quốc Gia Hà Nội',
        displayName: '144 Xuân Thủy, Dịch Vọng Hậu, Cầu Giấy, Hà Nội',
        latLng: LatLng(21.0375, 105.7825),
      ),
      OsmSuggestion(
        shortName: 'Đại học Bách Khoa Hà Nội',
        displayName: 'Số 1 Đại Cồ Việt, Bách Khoa, Hai Bà Trưng, Hà Nội',
        latLng: LatLng(21.0050, 105.8430),
      ),
      OsmSuggestion(
        shortName: 'Quận Cầu Giấy',
        displayName: 'Cầu Giấy, Hà Nội',
        latLng: LatLng(21.0359, 105.7908),
      ),
      OsmSuggestion(
        shortName: 'Quận Ba Đình',
        displayName: 'Ba Đình, Hà Nội',
        latLng: LatLng(21.0340, 105.8250),
      ),
      OsmSuggestion(
        shortName: 'Quận Đống Đa',
        displayName: 'Đống Đa, Hà Nội',
        latLng: LatLng(21.0180, 105.8270),
      ),
    ];
  }

  // ─── FORWARD GEOCODING ───────────────────────────────────────────────────
  /// Tim toa do tu chuoi dia chi (gioi han nghiem ngat trong lanh tho Viet Nam).
  Future<List<OsmSuggestion>> searchAddress(
    String query, {
    int limit = 5,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final res = await Dio().get(
        '$_nominatimBase/search',
        queryParameters: {
          'q': q,
          'format': 'json',
          'limit': 20, // Lấy nhiều để sau filter còn đủ
          'countrycodes': 'vn', // BẮT BUỘC chỉ Việt Nam
          'viewbox': _vnViewbox, // Viewbox giới hạn toàn Việt Nam
          'bounded': 1, // Giới hạn nghiêm ngặt
          'accept-language': 'vi', // Force Vietnamese
          'addressdetails': 1,
          'featuretype': 'street', // Chỉ lấy đường phố
        },
        options: Options(
          headers: _headers,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (res.data is! List) return [];
      final allItems = res.data as List;

      // Chỉ giữ lại các result thuộc class highway/road và nằm trong lãnh thổ Việt Nam
      final streetItems = allItems
          .where((item) {
            final lat = double.tryParse(item['lat'].toString()) ?? 0.0;
            final lon = double.tryParse(item['lon'].toString()) ?? 0.0;
            if (!isInsideVietnam(LatLng(lat, lon))) return false;

            final cls = item['class']?.toString() ?? '';
            final type = item['type']?.toString() ?? '';
            // Chấp nhận: highway (đường), waterway (một số đặt theo tên đường)
            if (cls == 'highway') return true;
            // Loại bỏ: house_number, amenity, building, shop, v.v.
            if (cls == 'place' && (type == 'house' || type == 'postbox')) {
              return false;
            }
            if (cls == 'amenity') return false;
            if (cls == 'building') return false;
            if (cls == 'shop') return false;
            if (type == 'house_number') return false;
            return false; // Mặc định loại bỏ nếu không phải highway
          })
          .take(limit)
          .toList();

      return streetItems.map((item) {
        final lat = double.tryParse(item['lat'].toString()) ?? 0.0;
        final lon = double.tryParse(item['lon'].toString()) ?? 0.0;
        final addr = item['address'] as Map? ?? {};
        // shortName chỉ là tên đường (road), không kèm số nhà
        final road =
            addr['road']?.toString() ?? item['display_name']?.toString() ?? q;
        final cleanedRoad = _cleanStreetName(road);
        final cleanedDisplay = _cleanStreetName(
          item['display_name']?.toString() ?? q,
        );
        return OsmSuggestion(
          displayName: cleanedDisplay,
          shortName: cleanedRoad,
          latLng: LatLng(lat, lon),
        );
      }).toList();
    } catch (_) {
      // ─── FALLBACK: Gọi Photon API nếu Nominatim bị lỗi (VD: Quá giới hạn request) ───
      try {
        final fallbackRes = await Dio().get(
          '$_photonBase/api/',
          queryParameters: {
            'q': q,
            'limit': limit,
            'lang': 'default',
            'bbox': '102.1,8.15,117.5,23.45', // Bounding box Việt Nam
          },
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        if (fallbackRes.data == null || fallbackRes.data['features'] == null) {
          return [];
        }
        // BUGFIX (data): tránh `as List` ném TypeError khi `features`
        // không phải List — coerce an toàn.
        final rawFeatures = fallbackRes.data['features'];
        final features = rawFeatures is List ? rawFeatures : const <dynamic>[];
        return features
            .where((f) {
              final props = f['properties'] as Map? ?? {};
              final countryCode = (props['countrycode'] ?? '')
                  .toString()
                  .toLowerCase();
              final country = (props['country'] ?? '').toString().toLowerCase();

              // BẮT BUỘC chỉ nhận kết quả thuộc Việt Nam
              if (countryCode.isNotEmpty && countryCode != 'vn') return false;
              if (country.isNotEmpty &&
                  !country.contains('viet') &&
                  !country.contains('việt')) {
                return false;
              }

              final name = props['name']?.toString() ?? '';
              final street = props['street']?.toString() ?? '';
              final state = props['state']?.toString() ?? '';
              final city = props['city']?.toString() ?? '';
              final district = props['district']?.toString() ?? '';

              // Loại bỏ tuyệt đối mọi kết quả chứa ký tự lạ (tiếng Thái, Lào, Khmer, v.v.)
              if (hasNonVietnameseScript(
                '$name $street $state $city $district',
              )) {
                return false;
              }

              final coords =
                  f['geometry']?['coordinates'] as List? ?? [0.0, 0.0];
              final lon = double.tryParse(coords[0].toString()) ?? 0.0;
              final lat = double.tryParse(coords[1].toString()) ?? 0.0;
              if (!isInsideVietnam(LatLng(lat, lon))) return false;

              final osmKey = props['osm_key']?.toString() ?? '';
              final osmValue = props['osm_value']?.toString() ?? '';
              // Loại bỏ các nút cây cầu vật lý (bridge) để tránh nhầm với tên đường/phố
              if (osmKey == 'bridge' || osmValue == 'bridge') return false;
              return true;
            })
            .map((f) {
              final props = f['properties'] as Map? ?? {};
              final coords =
                  f['geometry']?['coordinates'] as List? ?? [0.0, 0.0];
              final lon = double.tryParse(coords[0].toString()) ?? 0.0;
              final lat = double.tryParse(coords[1].toString()) ?? 0.0;

              final parts = <String>[];
              if (props['street'] != null) {
                parts.add(props['street'].toString());
              }
              if (props['district'] != null) {
                parts.add(props['district'].toString());
              }
              if (props['city'] != null) parts.add(props['city'].toString());
              if (props['state'] != null) parts.add(props['state'].toString());

              final name = props['name']?.toString() ?? q;
              final displayName = parts.isNotEmpty
                  ? '$name, ${parts.join(', ')}'
                  : name;
              final shortName = parts.isNotEmpty ? parts.join(', ') : name;

              if (hasNonVietnameseScript(displayName) ||
                  hasNonVietnameseScript(shortName)) {
                return null;
              }

              return OsmSuggestion(
                displayName: displayName,
                shortName: shortName,
                latLng: LatLng(lat, lon),
              );
            })
            .whereType<OsmSuggestion>()
            .toList();
      } catch (e2) {
        return [];
      }
    }
  }

  /// Chuẩn hóa bỏ dấu nhưng GIỮ NGUYÊN phụ âm (đặc biệt phân biệt 'd' và 'đ').
  /// Ngăn chặn việc 'diễn' bị nhầm thành 'điển' (Văn Điển) hoặc 'điền' (Đồng Điền).
  static String normalizePreservingD(String str) {
    const withDia =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyy'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYY';
    const withDiaOrig =
        'áàảãạâấầẩẫậăắằẳẵặéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵ'
        'ÁÀẢẠÂẤẦẨẪẬĂẮẰẲẴẶÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴ';
    String result = str;
    for (int i = 0; i < withDiaOrig.length; i++) {
      result = result.replaceAll(withDiaOrig[i], withDia[i]);
    }
    return result
        .toLowerCase()
        .replaceAll(RegExp(r'[,\.\-_/]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Kiểm tra mức độ liên quan nghiêm ngặt giữa query tìm kiếm và kết quả trả về.
  /// Bắt buộc mọi từ khóa chính của query (ví dụ: 'cau', 'dien') phải xuất hiện trong tên địa điểm.
  static bool _isStrictlyRelevant(
    String query,
    String shortName,
    String displayName,
  ) {
    final cleanQ = query.trim().toLowerCase();
    if (cleanQ.isEmpty) return false;

    final normQ = normalizePreservingD(cleanQ);
    final normTarget =
        '${normalizePreservingD(shortName)} ${normalizePreservingD(displayName)}';

    // Tách các từ trong query, bỏ qua các từ tiền tố
    final qWords = normQ
        .split(' ')
        .map((w) => w.trim())
        .where(
          (w) =>
              w.length > 1 &&
              !['so', 'tai', 'o', 'va', 'pho', 'duong'].contains(w),
        )
        .toList();

    if (qWords.isEmpty) return true;

    for (final word in qWords) {
      if (!normTarget.contains(word)) {
        return false;
      }
    }
    return true;
  }

  // ─── DANH MỤC ĐỊA ĐIỂM TRỌNG ĐIỂM VIỆT NAM (0ms Fast Search) ───────────────
  static const List<_VnPlaceEntry> _vnPlacesCatalog = [
    // ── Khu vực Trục Tây Bắc & Cầu Diễn - Bắc / Nam Từ Liêm ──
    _VnPlaceEntry(
      name: 'Đường Cầu Diễn',
      ward: 'Phúc Diễn',
      district: 'Bắc Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0435, 105.7600),
      aliases: [
        'cầu diễn',
        'cau dien',
        'đường cầu diễn',
        'duong cau dien',
        'ql32 cầu diễn',
      ],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Phường Cầu Diễn',
      ward: 'Cầu Diễn',
      district: 'Nam Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0360, 105.7620),
      aliases: ['phường cầu diễn', 'phuong cau dien', 'cầu diễn', 'cau dien'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Phường Phúc Diễn',
      ward: 'Phúc Diễn',
      district: 'Bắc Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0450, 105.7530),
      aliases: ['phúc diễn', 'phuc dien', 'phường phúc diễn'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Phường Phú Diễn',
      ward: 'Phú Diễn',
      district: 'Bắc Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0470, 105.7620),
      aliases: ['phú diễn', 'phu dien', 'đường phú diễn', 'phường phú diễn'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đại học Công Nghiệp Hà Nội (Cơ sở Nhổn - Cầu Diễn)',
      ward: 'Minh Khai',
      district: 'Bắc Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0540, 105.7350),
      aliases: [
        'công nghiệp',
        'cong nghiep',
        'haui',
        'dhcn',
        '298 cầu diễn',
        'nhổn',
      ],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Đường Nhổn (Quốc Lộ 32)',
      ward: 'Minh Khai',
      district: 'Bắc Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0560, 105.7280),
      aliases: ['nhổn', 'nhon', 'đường nhổn', 'phố nhổn', 'ga nhổn'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Xuân Phương',
      ward: 'Xuân Phương',
      district: 'Nam Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0320, 105.7420),
      aliases: ['xuân phương', 'xuan phuong', 'đường xuân phương'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Hồ Tùng Mậu',
      ward: 'Mai Dịch',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0385, 105.7725),
      aliases: ['hồ tùng mậu', 'ho tung mau', 'đường hồ tùng mậu'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đại học Thương Mại (TMU)',
      ward: 'Mai Dịch',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0366, 105.7744),
      aliases: ['thương mại', 'thuong mai', 'tmu', 'dhtm', '79 hồ tùng mậu'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Đường Mai Dịch',
      ward: 'Mai Dịch',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0416, 105.7766),
      aliases: ['mai dịch', 'mai dich', 'phường mai dịch'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Cổ Nhuế',
      ward: 'Cổ Nhuế',
      district: 'Bắc Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0650, 105.7750),
      aliases: ['cổ nhuế', 'co nhue', 'đường cổ nhuế'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'KĐT Mỹ Đình 1',
      ward: 'Cầu Diễn',
      district: 'Nam Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0325, 105.7680),
      aliases: ['mỹ đình 1', 'my dinh 1', 'kđt mỹ đình 1'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Đường Lê Đức Thọ',
      ward: 'Mỹ Đình 2',
      district: 'Nam Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0300, 105.7680),
      aliases: [
        'lê đức thọ',
        'le duc tho',
        'đường lê đức thọ',
        'sân vận động mỹ đình',
      ],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Lê Quang Đạo',
      ward: 'Mễ Trì',
      district: 'Nam Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0180, 105.7690),
      aliases: ['lê quang đạo', 'le quang dao', 'đường lê quang đạo'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Phạm Hùng',
      ward: 'Mỹ Đình 1',
      district: 'Nam Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0250, 105.7780),
      aliases: ['phạm hùng', 'pham hung', 'đường phạm hùng', 'bến xe mỹ đình'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Mễ Trì',
      ward: 'Mễ Trì',
      district: 'Nam Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0120, 105.7800),
      aliases: ['mễ trì', 'me tri', 'đường mễ trì'],
      isStreet: true,
    ),

    // ── Khu vực Quận Cầu Giấy ──
    _VnPlaceEntry(
      name: 'Đường Cầu Giấy',
      ward: 'Quan Hoa',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0359, 105.7908),
      aliases: ['cầu giấy', 'cau giay', 'đường cầu giấy', 'phố cầu giấy'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Xuân Thủy',
      ward: 'Dịch Vọng Hậu',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0368, 105.7865),
      aliases: ['xuân thủy', 'xuan thuy', 'đường xuân thủy'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đại học Quốc Gia Hà Nội (VNU)',
      ward: 'Dịch Vọng Hậu',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0378, 105.7818),
      aliases: ['quốc gia', 'quoc gia', 'vnu', 'đhqg', '144 xuân thủy'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Đại học Sư Phạm Hà Nội',
      ward: 'Dịch Vọng Hậu',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0372, 105.7825),
      aliases: ['sư phạm', 'su pham', 'hnue', 'dhsp', '136 xuân thủy'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Đường Trần Thái Tông',
      ward: 'Dịch Vọng',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0315, 105.7865),
      aliases: ['trần thái tông', 'tran thai tong', 'đường trần thái tông'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Duy Tân',
      ward: 'Dịch Vọng Hậu',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0310, 105.7820),
      aliases: ['duy tân', 'duy tan', 'phố duy tân', 'đường duy tân'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Hoàng Quốc Việt',
      ward: 'Nghĩa Đô',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0460, 105.7950),
      aliases: ['hoàng quốc việt', 'hoang quoc viet', 'đường hoàng quốc việt'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Nguyễn Phong Sắc',
      ward: 'Dịch Vọng Hậu',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0370, 105.7900),
      aliases: ['nguyễn phong sắc', 'nguyen phong sac'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Trần Duy Hưng',
      ward: 'Trung Hòa',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0085, 105.7965),
      aliases: ['trần duy hưng', 'tran duy hung', 'đường trần duy hưng'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Trung Kính',
      ward: 'Yên Hòa',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0150, 105.7960),
      aliases: ['trung kính', 'trung kinh', 'đường trung kính'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Nguyễn Khang',
      ward: 'Yên Hòa',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0180, 105.8030),
      aliases: ['nguyễn khang', 'nguyen khang'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Nghĩa Tân',
      ward: 'Nghĩa Tân',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0450, 105.7925),
      aliases: ['nghĩa tân', 'nghia tan', 'khu tập thể nghĩa tân'],
      isStreet: true,
    ),

    // ── Khu vực Quận Ba Đình ──
    _VnPlaceEntry(
      name: 'Đường Vĩnh Phúc',
      ward: 'Vĩnh Phúc',
      district: 'Ba Đình',
      city: 'Hà Nội',
      latLng: LatLng(21.0425, 105.8115),
      aliases: ['vĩnh phúc', 'vinh phuc', 'phố vĩnh phúc', 'đường vĩnh phúc'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Đội Cấn',
      ward: 'Đội Cấn',
      district: 'Ba Đình',
      city: 'Hà Nội',
      latLng: LatLng(21.0360, 105.8200),
      aliases: ['đội cấn', 'doi can', 'phố đội cấn', 'đường đội cấn'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Kim Mã',
      ward: 'Kim Mã',
      district: 'Ba Đình',
      city: 'Hà Nội',
      latLng: LatLng(21.0315, 105.8190),
      aliases: ['kim mã', 'kim ma', 'phố kim mã', 'đường kim mã'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Liễu Giai',
      ward: 'Liễu Giai',
      district: 'Ba Đình',
      city: 'Hà Nội',
      latLng: LatLng(21.0360, 105.8140),
      aliases: ['liễu giai', 'lieu giai', 'phố liễu giai'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Đào Tấn',
      ward: 'Cống Vị',
      district: 'Ba Đình',
      city: 'Hà Nội',
      latLng: LatLng(21.0330, 105.8100),
      aliases: ['đào tấn', 'dao tan', 'phố đào tấn'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Hoàng Hoa Thám',
      ward: 'Ngọc Hà',
      district: 'Ba Đình',
      city: 'Hà Nội',
      latLng: LatLng(21.0430, 105.8180),
      aliases: ['hoàng hoa thám', 'hoang hoa tham'],
      isStreet: true,
    ),

    // ── Khu vực Quận Đống Đa ──
    _VnPlaceEntry(
      name: 'Đường Chùa Láng',
      ward: 'Láng Thượng',
      district: 'Đống Đa',
      city: 'Hà Nội',
      latLng: LatLng(21.0253, 105.8037),
      aliases: ['chùa láng', 'chua lang', 'phố chùa láng', 'đường chùa láng'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đại học Ngoại Thương (FTU)',
      ward: 'Láng Thượng',
      district: 'Đống Đa',
      city: 'Hà Nội',
      latLng: LatLng(21.0264, 105.8055),
      aliases: ['ngoại thương', 'ngoai thuong', 'ftu', '91 chùa láng'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Đại học Giao Thông Vận Tải (UTC)',
      ward: 'Láng Thượng',
      district: 'Đống Đa',
      city: 'Hà Nội',
      latLng: LatLng(21.0286, 105.8028),
      aliases: [
        'giao thông vận tải',
        'giao thong van tai',
        'utc',
        'dhgtvt',
        '3 cầu giấy',
      ],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Đường Láng',
      ward: 'Láng Thượng',
      district: 'Đống Đa',
      city: 'Hà Nội',
      latLng: LatLng(21.0180, 105.8150),
      aliases: ['đường láng', 'duong lang', 'láng'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Chùa Bộc',
      ward: 'Quang Trung',
      district: 'Đống Đa',
      city: 'Hà Nội',
      latLng: LatLng(21.0080, 105.8270),
      aliases: ['chùa bộc', 'chua boc', 'phố chùa bộc'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Học viện Ngân Hàng (BA)',
      ward: 'Quang Trung',
      district: 'Đống Đa',
      city: 'Hà Nội',
      latLng: LatLng(21.0090, 105.8280),
      aliases: ['ngân hàng', 'ngan hang', 'hvnh', 'ba', '12 chùa bộc'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Đại học Y Hà Nội (HMU)',
      ward: 'Kim Liên',
      district: 'Đống Đa',
      city: 'Hà Nội',
      latLng: LatLng(21.0042, 105.8306),
      aliases: ['y hà nội', 'y ha noi', 'hmu', 'dhy', '1 tôn thất tùng'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Đường Thái Hà',
      ward: 'Trung Liệt',
      district: 'Đống Đa',
      city: 'Hà Nội',
      latLng: LatLng(21.0140, 105.8200),
      aliases: ['thái hà', 'thai ha', 'phố thái hà'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Tây Sơn',
      ward: 'Quang Trung',
      district: 'Đống Đa',
      city: 'Hà Nội',
      latLng: LatLng(21.0110, 105.8230),
      aliases: ['tây sơn', 'tay son', 'phố tây sơn'],
      isStreet: true,
    ),

    // ── Khu vực Quận Thanh Xuân & Hà Đông ──
    _VnPlaceEntry(
      name: 'Đường Nguyễn Trãi',
      ward: 'Thượng Đình',
      district: 'Thanh Xuân',
      city: 'Hà Nội',
      latLng: LatLng(20.9980, 105.8118),
      aliases: ['nguyễn trãi', 'nguyen trai', 'đường nguyễn trãi'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Khuất Duy Tiến',
      ward: 'Thanh Xuân Bắc',
      district: 'Thanh Xuân',
      city: 'Hà Nội',
      latLng: LatLng(20.9960, 105.7950),
      aliases: ['khuất duy tiến', 'khuat duy tien'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Đường Lê Văn Lương',
      ward: 'Nhân Chính',
      district: 'Thanh Xuân',
      city: 'Hà Nội',
      latLng: LatLng(21.0040, 105.8020),
      aliases: ['lê văn lương', 'le van luong'],
      isStreet: true,
    ),
    _VnPlaceEntry(
      name: 'Học viện Bưu chính Viễn thông (PTIT)',
      ward: 'Mộ Lao',
      district: 'Hà Đông',
      city: 'Hà Nội',
      latLng: LatLng(20.9800, 105.7870),
      aliases: ['bưu chính', 'buu chinh', 'ptit', 'hvbc', 'km10 nguyễn trãi'],
      isStreet: false,
    ),

    // ── Khu vực Quận Hai Bà Trưng ──
    _VnPlaceEntry(
      name: 'Đại học Bách Khoa Hà Nội (HUST)',
      ward: 'Bách Khoa',
      district: 'Hai Bà Trưng',
      city: 'Hà Nội',
      latLng: LatLng(21.0051, 105.8433),
      aliases: ['bách khoa', 'bach khoa', 'hust', 'dhbk', '1 đại cồ việt'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Đại học Kinh Tế Quốc Dân (NEU)',
      ward: 'Đồng Tâm',
      district: 'Hai Bà Trưng',
      city: 'Hà Nội',
      latLng: LatLng(20.9996, 105.8428),
      aliases: [
        'kinh tế quốc dân',
        'kinh te quoc dan',
        'neu',
        'ktqd',
        '207 giải phóng',
      ],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Đại học Xây Dựng Hà Nội (HUCE)',
      ward: 'Đồng Tâm',
      district: 'Hai Bà Trưng',
      city: 'Hà Nội',
      latLng: LatLng(21.0020, 105.8440),
      aliases: [
        'xây dựng',
        'xay dung',
        'huce',
        'nuce',
        'dhxd',
        '55 giải phóng',
      ],
      isStreet: false,
    ),

    // ── Danh mục Quận / Thành Phố Trung Tâm ──
    _VnPlaceEntry(
      name: 'Quận Cầu Giấy',
      district: 'Cầu Giấy',
      city: 'Hà Nội',
      latLng: LatLng(21.0359, 105.7908),
      aliases: ['cầu giấy', 'cau giay', 'quận cầu giấy'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Quận Nam Từ Liêm',
      district: 'Nam Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0142, 105.7645),
      aliases: ['nam từ liêm', 'nam tu liem', 'quận nam từ liêm'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Quận Bắc Từ Liêm',
      district: 'Bắc Từ Liêm',
      city: 'Hà Nội',
      latLng: LatLng(21.0632, 105.7602),
      aliases: ['bắc từ liêm', 'bac tu liem', 'quận bắc từ liêm'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Quận Ba Đình',
      district: 'Ba Đình',
      city: 'Hà Nội',
      latLng: LatLng(21.0341, 105.8239),
      aliases: ['ba đình', 'ba dinh', 'quận ba đình'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Quận Đống Đa',
      district: 'Đống Đa',
      city: 'Hà Nội',
      latLng: LatLng(21.0180, 105.8290),
      aliases: ['đống đa', 'dong da', 'quận đống đa'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Quận Thanh Xuân',
      district: 'Thanh Xuân',
      city: 'Hà Nội',
      latLng: LatLng(20.9937, 105.8122),
      aliases: ['thanh xuân', 'thanh xuan', 'quận thanh xuân'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Quận Hai Bà Trưng',
      district: 'Hai Bà Trưng',
      city: 'Hà Nội',
      latLng: LatLng(21.0066, 105.8504),
      aliases: ['hai bà trưng', 'hai ba trung', 'quận hai bà trưng'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Quận Hoàn Kiếm',
      district: 'Hoàn Kiếm',
      city: 'Hà Nội',
      latLng: LatLng(21.0307, 105.8524),
      aliases: ['hoàn kiếm', 'hoan kiem', 'quận hoàn kiếm', 'hồ gươm'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Quận Tây Hồ',
      district: 'Tây Hồ',
      city: 'Hà Nội',
      latLng: LatLng(21.0718, 105.8230),
      aliases: ['tây hồ', 'tay ho', 'quận tây hồ', 'hồ tây'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Quận Hà Đông',
      district: 'Hà Đông',
      city: 'Hà Nội',
      latLng: LatLng(20.9723, 105.7766),
      aliases: ['hà đông', 'ha dong', 'quận hà đông'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Quận Hoàng Mai',
      district: 'Hoàng Mai',
      city: 'Hà Nội',
      latLng: LatLng(20.9765, 105.8453),
      aliases: ['hoàng mai', 'hoang mai', 'quận hoàng mai'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Quận Long Biên',
      district: 'Long Biên',
      city: 'Hà Nội',
      latLng: LatLng(21.0362, 105.8893),
      aliases: ['long biên', 'long bien', 'quận long biên'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Thành phố Hà Nội',
      district: '',
      city: 'Hà Nội',
      latLng: LatLng(21.0285, 105.8542),
      aliases: ['hà nội', 'ha noi', 'thủ đô hà nội'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Thành phố Hồ Chí Minh',
      district: '',
      city: 'TP. Hồ Chí Minh',
      latLng: LatLng(10.7769, 106.7009),
      aliases: ['hồ chí minh', 'ho chi minh', 'sài gòn', 'sai gon', 'tp hcm'],
      isStreet: false,
    ),
    _VnPlaceEntry(
      name: 'Thành phố Đà Nẵng',
      district: '',
      city: 'Đà Nẵng',
      latLng: LatLng(16.0544, 108.2022),
      aliases: ['đà nẵng', 'da nang'],
      isStreet: false,
    ),
  ];

  /// Tim toa do dau tien tu dia chi (ho tro ca quan huyen, truong hoc, tuyen pho).
  Future<LatLng?> geocode(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    final houseMatch = RegExp(
      r'^((?:số|ngõ|ngách|hẻm)?\s*\d+[a-zA-Z]?(?:/\d+[a-zA-Z]?)*)\s+(.*)$',
      caseSensitive: false,
    ).firstMatch(q);
    final String cleanStreet = (houseMatch?.group(2) ?? q).trim();
    final normStreet = normalizePreservingD(cleanStreet);

    // 1. Ưu tiên match từ điển địa điểm Việt Nam phản hồi 0ms
    for (final place in _vnPlacesCatalog) {
      final normName = normalizePreservingD(place.name);
      if (normName == normStreet ||
          normName.contains(normStreet) ||
          normStreet.contains(normName)) {
        return place.latLng;
      }
      for (final alias in place.aliases) {
        final normAlias = normalizePreservingD(alias);
        if (normAlias == normStreet ||
            normAlias.contains(normStreet) ||
            normStreet.contains(normAlias)) {
          return place.latLng;
        }
      }
    }

    // 2. Thu Photon API
    final photon = await _searchPhoton(cleanStreet);
    if (photon != null) return photon;

    // 3. Fallback Nominatim
    final results = await searchAddress(cleanStreet, limit: 1);
    return results.isNotEmpty ? results.first.latLng : null;
  }

  /// Tìm kiếm danh sách gợi ý địa chỉ linh hoạt cho autocomplete.
  /// Kết hợp:
  /// 1. Phân tích số nhà + tra cứu phố / phường / quận trọng điểm (phản hồi 0ms)
  /// 2. Lọc nghiêm ngặt phụ âm 'd' vs 'đ' để tránh lẫn lộn 'Cầu Diễn' với 'Cầu Văn Điển'
  /// 3. Tra cứu trực tuyến qua OSM Nominatim & Photon với kiểm tra độ liên quan chặt chẽ
  Future<List<OsmSuggestion>> searchSuggestions(
    String query, {
    int limit = 6,
  }) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final suggestions = <OsmSuggestion>[];
    final addedKeys = <String>{};

    void addSuggestion(OsmSuggestion s) {
      if (!isInsideVietnam(s.latLng)) return;
      final key =
          '${s.latLng.latitude.toStringAsFixed(4)}_${s.latLng.longitude.toStringAsFixed(4)}_${s.shortName}';
      if (!addedKeys.contains(key)) {
        addedKeys.add(key);
        suggestions.add(s);
      }
    }

    // 1. Phân tích số nhà (VD: "143 cầu diễn", "số 42 vĩnh phúc", "ngõ 10 chùa láng")
    final houseMatch = RegExp(
      r'^((?:số|ngõ|ngách|hẻm)?\s*\d+[a-zA-Z]?(?:/\d+[a-zA-Z]?)*)\s+(.*)$',
      caseSensitive: false,
    ).firstMatch(q);
    final String? houseNo = houseMatch?.group(1)?.trim();
    final String rawStreetPart = (houseMatch?.group(2) ?? q).trim();
    final String normStreet = normalizePreservingD(rawStreetPart);

    // 2. Tra cứu tức thì trong từ điển địa điểm Việt Nam (_vnPlacesCatalog) (0ms response)
    for (final place in _vnPlacesCatalog) {
      final normPlaceName = normalizePreservingD(place.name);
      final normAliases = place.aliases
          .map((a) => normalizePreservingD(a))
          .toList();

      bool isMatch = false;
      if (normStreet.length == 1) {
        // Nếu mới gõ 1 ký tự (VD: 'c'), chỉ khớp các từ bắt đầu bằng chữ đó
        final words = normPlaceName.split(' ');
        isMatch =
            words.any((w) => w.startsWith(normStreet)) ||
            normAliases.any(
              (a) => a.split(' ').any((w) => w.startsWith(normStreet)),
            );
      } else {
        // Gõ từ 2 ký tự trở lên (VD: 'ca', 'cầ', 'cả', 'cầu', 'cau')
        isMatch =
            normPlaceName.contains(normStreet) ||
            normPlaceName.split(' ').any((w) => w.startsWith(normStreet));
        if (!isMatch) {
          for (final alias in normAliases) {
            if (alias == normStreet ||
                alias.contains(normStreet) ||
                alias.split(' ').any((w) => w.startsWith(normStreet))) {
              isMatch = true;
              break;
            }
          }
        }
      }

      if (isMatch) {
        String shortName;
        String displayName;

        if (houseNo != null && place.isStreet) {
          final prefix = houseNo[0].toUpperCase() + houseNo.substring(1);
          shortName = '$prefix ${place.name}';
          final parts = <String>[shortName];
          if (place.ward.isNotEmpty && !place.name.contains(place.ward)) {
            parts.add('Phường ${place.ward}');
          }
          if (place.district.isNotEmpty &&
              !place.name.contains(place.district)) {
            parts.add('Quận ${place.district}');
          }
          if (place.city.isNotEmpty) parts.add(place.city);
          displayName = parts.join(', ');
        } else {
          shortName = place.name;
          displayName = place.fullDisplayName;
        }

        addSuggestion(
          OsmSuggestion(
            displayName: displayName,
            shortName: shortName,
            latLng: place.latLng,
          ),
        );
      }
    }

    // 3. Tra cứu trực tuyến nếu chưa đủ kết quả và từ khóa tên đường đủ dài (>= 3 ký tự)
    // TUYỆT ĐỐI không gửi từ khóa quá ngắn (1-2 ký tự) lên online API để tránh nhận dữ liệu rác ngoài nước
    final cleanStreetLen = rawStreetPart.trim().length;
    if (suggestions.length < limit && cleanStreetLen >= 3) {
      try {
        final onlineResults = await searchAddress(rawStreetPart, limit: limit);
        for (final s in onlineResults) {
          if (hasNonVietnameseScript(s.displayName) ||
              hasNonVietnameseScript(s.shortName)) {
            continue;
          }
          if (_isStrictlyRelevant(rawStreetPart, s.shortName, s.displayName)) {
            if (houseNo != null) {
              final prefix = houseNo[0].toUpperCase() + houseNo.substring(1);
              final withHouseShort = '$prefix ${s.shortName}';
              final withHouseDisplay = '$prefix ${s.displayName}';
              addSuggestion(
                OsmSuggestion(
                  displayName: withHouseDisplay,
                  shortName: withHouseShort,
                  latLng: s.latLng,
                ),
              );
            } else {
              addSuggestion(s);
            }
          }
        }
      } catch (_) {}
    }

    // 4. Nếu vẫn còn ít kết quả và query chưa có "Hà Nội" và từ khóa đủ dài (>= 3 ký tự)
    if (suggestions.length < 3 &&
        cleanStreetLen >= 3 &&
        !normStreet.contains('ha noi')) {
      try {
        final hnResults = await searchAddress(
          '$rawStreetPart, Hà Nội',
          limit: limit,
        );
        for (final s in hnResults) {
          if (hasNonVietnameseScript(s.displayName) ||
              hasNonVietnameseScript(s.shortName)) {
            continue;
          }
          if (_isStrictlyRelevant(rawStreetPart, s.shortName, s.displayName)) {
            if (houseNo != null) {
              final prefix = houseNo[0].toUpperCase() + houseNo.substring(1);
              addSuggestion(
                OsmSuggestion(
                  displayName: '$prefix ${s.displayName}',
                  shortName: '$prefix ${s.shortName}',
                  latLng: s.latLng,
                ),
              );
            } else {
              addSuggestion(s);
            }
          }
        }
      } catch (_) {}
    }

    return suggestions.take(limit).toList();
  }

  // ─── VIETNAM STRUCTURED GEOCODING ─────────────────────────────────────────
  /// Tìm toạ độ theo cấu trúc hành chính Việt Nam với chiến lược 2 bước:
  ///   Bước 1 — Geocode tỉnh/thành phố để lấy toạ độ tâm tỉnh.
  ///   Bước 2 — Geocode huyện/xã trong viewbox ±1° quanh tâm tỉnh.
  ///
  /// Tại sao dùng 2 bước: Nominatim structured search với `city=Giao Hà` không
  /// hoạt động tốt cho cấp xã VN (OSM index xã là village/hamlet, không phải city).
  /// Viewbox chặt quanh tỉnh đảm bảo không bao giờ match sang tỉnh khác.
  Future<({LatLng latLng, bool exact})?> geocodeVietnamese({
    String? ward,
    String? district,
    required String province,
  }) async {
    final cleanProvince = _stripAdminPrefix(province);
    if (cleanProvince.isEmpty) return null;

    // ── Bước 1: Tìm tâm tỉnh ─────────────────────────────────────────────
    LatLng? provinceCenter = await searchWithViewbox(
      query: cleanProvince,
      viewbox: _vnViewbox, // Giới hạn toàn VN
      bounded: false, // Không bound cứng — VN viewbox đủ rộng
    );
    provinceCenter ??= await searchWithViewbox(
      query: '$cleanProvince, Vietnam',
      viewbox: _vnViewbox,
      bounded: false,
    );

    // Nếu không tìm được tỉnh → trả về null (không đoán mò)
    if (provinceCenter == null) return null;

    // Chỉ cần tỉnh thì dừng ở đây
    if ((ward == null || ward.isEmpty) &&
        (district == null || district.isEmpty)) {
      return (latLng: provinceCenter, exact: true);
    }

    // ── Bước 2: Viewbox chặt ±1° quanh tâm tỉnh ─────────────────────────
    final double pLat = provinceCenter.latitude;
    final double pLon = provinceCenter.longitude;
    // ±1° ≈ 110km — đủ bao phủ mọi tỉnh VN, không chồng lấp tỉnh khác
    final String tightBox =
        '${(pLon - 1.0).toStringAsFixed(4)},${(pLat - 1.0).toStringAsFixed(4)},'
        '${(pLon + 1.0).toStringAsFixed(4)},${(pLat + 1.0).toStringAsFixed(4)}';

    final cleanDistrict = _stripAdminPrefix(district ?? '');
    final cleanWard = _stripAdminPrefix(ward ?? '');

    // Thử tìm xã trong viewbox chặt
    if (cleanWard.isNotEmpty) {
      // Thử kết hợp xã + huyện
      if (cleanDistrict.isNotEmpty) {
        final r = await searchWithViewbox(
          query: '$cleanWard, $cleanDistrict',
          viewbox: tightBox,
          bounded: true,
        );
        if (r != null) return (latLng: r, exact: true);
      }
      // Thử xã đơn trong viewbox tỉnh
      final r2 = await searchWithViewbox(
        query: cleanWard,
        viewbox: tightBox,
        bounded: true,
      );
      if (r2 != null) return (latLng: r2, exact: true);
    }

    // Thử tìm huyện trong viewbox chặt
    if (cleanDistrict.isNotEmpty) {
      final r = await searchWithViewbox(
        query: cleanDistrict,
        viewbox: tightBox,
        bounded: true,
      );
      if (r != null) return (latLng: r, exact: true);
    }

    // ── Bước 3: Nếu Nominatim tìm xã/huyện thất bại, gọi Photon API làm Fallback ──
    // Photon API (dựa trên Elasticsearch) thường tìm các xã/thôn ở quê tốt hơn Nominatim.
    if (cleanWard.isNotEmpty || cleanDistrict.isNotEmpty) {
      final fallbackQuery =
          '${cleanWard.isNotEmpty ? "$cleanWard, " : ""}${cleanDistrict.isNotEmpty ? "$cleanDistrict, " : ""}$cleanProvince';
      final photonLatLng = await _searchPhoton(fallbackQuery);
      if (photonLatLng != null) {
        // Trả về kết quả từ Photon
        return (latLng: photonLatLng, exact: true);
      }
    }

    // Fallback cuối cùng về tâm tỉnh (đúng tỉnh, chỉ không đúng huyện/xã)
    return (latLng: provinceCenter, exact: false);
  }

  /// Gọi Photon API để Geocode text tự do (Fallback khi Nominatim quá khắt khe)
  Future<LatLng?> _searchPhoton(String query) async {
    try {
      final res = await Dio().get(
        '$_photonBase/api',
        queryParameters: {'q': query, 'limit': 1},
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (res.data != null && res.data['features'] != null) {
        // BUGFIX (data): tránh `as List` ném TypeError khi `features`
        // không phải List — coerce an toàn.
        final rawFeatures = res.data['features'];
        final features = rawFeatures is List ? rawFeatures : const <dynamic>[];
        if (features.isNotEmpty) {
          final firstFeature = features[0];
          final geom = firstFeature is Map ? firstFeature['geometry'] : null;
          if (geom is Map && geom['coordinates'] != null) {
            final rawCoords = geom['coordinates'];
            final coords = rawCoords is List ? rawCoords : const <dynamic>[];
            if (coords.length >= 2) {
              final lon = double.tryParse(coords[0].toString());
              final lat = double.tryParse(coords[1].toString());
              if (lat != null && lon != null) {
                return LatLng(lat, lon);
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Viewbox toàn lãnh thổ Việt Nam: Tây→Đông: 102.1°–109.5°, Nam→Bắc: 8.5°–23.4°
  static const String _vnViewbox = '102.1,8.5,109.5,23.4';

  /// Free-text search có kèm viewbox để hạn chế vùng tìm kiếm. Public.
  /// [bounded]=true: chỉ trả kết quả trong viewbox (strict).
  /// [bounded]=false: ưu tiên kết quả trong viewbox nhưng vẫn tìm ngoài nếu không có.
  Future<LatLng?> searchWithViewbox({
    required String query,
    required String viewbox,
    bool bounded = false,
  }) async {
    if (query.trim().isEmpty) return null;
    try {
      final res = await Dio().get(
        '$_nominatimBase/search',
        queryParameters: {
          'q': query.trim(),
          'format': 'json',
          'limit': 1,
          'countrycodes': 'vn',
          'accept-language': 'vi', // Force Vietnamese
          'viewbox': viewbox,
          'bounded': bounded ? 1 : 0,
          'addressdetails': 0,
        },
        options: Options(
          headers: _headers,
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (res.data is! List || (res.data as List).isEmpty) return null;
      final item = (res.data as List).first;
      // BUGFIX (data): tránh NoSuchMethodError khi phần tử không phải Map.
      if (item is! Map) return null;
      final lat = double.tryParse(item['lat'].toString());
      final lon = double.tryParse(item['lon'].toString());
      if (lat == null || lon == null) return null;
      return LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }

  /// Xoá tiền tố hành chính tiếng Việt để gửi tên gốc lên OSM.
  /// VD: "Xã Giao Hà" → "Giao Hà", "Tỉnh Nam Định" → "Nam Định"
  static String _stripAdminPrefix(String name) {
    const prefixes = [
      'Thành phố ',
      'Thành Phố ',
      'Tỉnh ',
      'Huyện ',
      'Quận ',
      'Thị xã ',
      'Thị Xã ',
      'Thị trấn ',
      'Thị Trấn ',
      'Phường ',
      'Xã ',
    ];
    var result = name.trim();
    for (final p in prefixes) {
      if (result.startsWith(p)) {
        result = result.substring(p.length).trim();
        break;
      }
    }
    return result;
  }

  /// Làm sạch tên đường tiếng Anh lẫn lộn từ OSM
  static String _cleanStreetName(String rawName) {
    if (rawName.isEmpty) return rawName;
    String name = rawName;
    for (final rx in [
      RegExp(r'\bRoad\b', caseSensitive: false),
      RegExp(r'\bStreet\b', caseSensitive: false),
      RegExp(r'\bAvenue\b', caseSensitive: false),
      RegExp(r'\bBoulevard\b', caseSensitive: false),
      RegExp(r'\bHighway\b', caseSensitive: false),
      RegExp(r'\bAlley\b', caseSensitive: false),
      RegExp(r'\bLane\b', caseSensitive: false),
    ]) {
      name = name.replaceAll(rx, '').trim();
    }
    // Remove extra commas
    name = name.replaceAll(RegExp(r',\s*,'), ',').trim();
    name = name.replaceAll(RegExp(r',\s*$'), '').trim();
    return name;
  }

  // ─── REVERSE GEOCODING ───────────────────────────────────────────────────
  /// Dich toa do (lat, lon) thanh dia chi chi tiet [OsmAddress].
  Future<OsmAddress?> reverseGeocode(
    double lat,
    double lon, {
    String? provinceHint,
  }) async {
    try {
      final res = await Dio().get(
        '$_nominatimBase/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'format': 'json',
          'addressdetails': 1,
          'accept-language': 'vi', // Force Vietnamese
          'email': 'contact@stayhub.vn',
        },
        options: Options(
          headers: _headers,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (res.data == null || res.data['address'] == null) return null;
      final a = res.data['address'] as Map;

      final city =
          a['city']?.toString() ??
          a['state']?.toString() ??
          a['province']?.toString() ??
          '';
      final district =
          a['city_district']?.toString() ??
          a['county']?.toString() ??
          a['district']?.toString() ??
          '';
      final ward =
          a['suburb']?.toString() ??
          a['quarter']?.toString() ??
          a['village']?.toString() ??
          a['neighbourhood']?.toString() ??
          a['hamlet']?.toString() ??
          a['town']?.toString() ??
          a['residential']?.toString() ??
          a['municipality']?.toString() ??
          '';
      final rawStreet =
          a['road']?.toString() ??
          a['pedestrian']?.toString() ??
          a['path']?.toString() ??
          a['footway']?.toString() ??
          a['residential']?.toString() ??
          a['street']?.toString() ??
          '';

      String street = _cleanStreetName(rawStreet);
      if (street.toLowerCase().startsWith('đường ')) {
        street = street.substring(6).trim();
      } else if (street.toLowerCase().startsWith('phố ')) {
        street = street.substring(4).trim();
      }
      final houseNumber = a['house_number']?.toString() ?? '';

      // displayAddress: Chi ghep Phuong/Quan/TP - KHONG dung street
      // vi OSM tra ten duong khong dau tieng Viet (Cau Giay thay vi Cau Giay)
      final displayParts = <String>[];
      if (ward.isNotEmpty) displayParts.add(ward);
      if (district.isNotEmpty) displayParts.add(district);
      if (city.isNotEmpty) displayParts.add(city);

      return OsmAddress(
        province: resolveOld63Province(
          city,
          district,
          provinceHint: provinceHint,
        ),
        district: district,
        ward: ward,
        street: street,
        houseNumber: houseNumber,
        displayAddress: displayParts.join(', '),
      );
    } catch (_) {
      // ─── FALLBACK 1: Gọi QGIS Nominatim API (Unblocked) ───
      try {
        final qgisRes = await Dio().get(
          'https://nominatim.qgis.org/reverse',
          queryParameters: {
            'lat': lat,
            'lon': lon,
            'format': 'json',
            'addressdetails': 1,
          },
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        if (qgisRes.data != null && qgisRes.data['address'] != null) {
          final a = qgisRes.data['address'] as Map;
          final city =
              a['city']?.toString() ??
              a['state']?.toString() ??
              a['province']?.toString() ??
              '';
          final district =
              a['city_district']?.toString() ??
              a['county']?.toString() ??
              a['district']?.toString() ??
              '';
          final ward =
              a['suburb']?.toString() ??
              a['quarter']?.toString() ??
              a['village']?.toString() ??
              a['neighbourhood']?.toString() ??
              '';
          final street =
              a['road']?.toString() ??
              a['pedestrian']?.toString() ??
              a['path']?.toString() ??
              a['footway']?.toString() ??
              a['residential']?.toString() ??
              a['street']?.toString() ??
              '';
          final houseNumber = a['house_number']?.toString() ?? '';

          final display = <String>[];
          if (houseNumber.isNotEmpty) display.add(houseNumber);
          if (street.isNotEmpty) display.add(street);
          if (ward.isNotEmpty) display.add(ward);
          if (district.isNotEmpty) display.add(district);
          if (city.isNotEmpty) display.add(city);

          final cleanStreet = _cleanStreetName(street);
          final displayParts = <String>[];
          if (ward.isNotEmpty) displayParts.add(ward);
          if (district.isNotEmpty) displayParts.add(district);
          if (city.isNotEmpty) displayParts.add(city);

          return OsmAddress(
            province: resolveOld63Province(city, district),
            district: district,
            ward: ward,
            street: cleanStreet,
            houseNumber: houseNumber,
            displayAddress: displayParts.join(', '),
          );
        }
      } catch (e1) {} // ignore: empty_catches

      // ─── FALLBACK 2: Gọi Photon API Reverse Geocode ───
      try {
        final fallbackRes = await Dio().get(
          '$_photonBase/reverse',
          queryParameters: {'lon': lon, 'lat': lat, 'lang': 'default'},
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        if (fallbackRes.data != null && fallbackRes.data['features'] != null) {
          // BUGFIX (data): tránh `as List` ném TypeError khi `features`
          // không phải List — coerce an toàn.
          final rawFeatures = fallbackRes.data['features'];
          final features = rawFeatures is List
              ? rawFeatures
              : const <dynamic>[];
          if (features.isNotEmpty) {
            final firstFeature = features[0];
            final props =
                (firstFeature is Map ? firstFeature['properties'] : null)
                    as Map? ??
                {};
            final city =
                props['city']?.toString() ?? props['state']?.toString() ?? '';
            final district =
                props['district']?.toString() ??
                props['county']?.toString() ??
                '';
            final ward =
                props['suburb']?.toString() ??
                props['quarter']?.toString() ??
                props['village']?.toString() ??
                props['neighbourhood']?.toString() ??
                props['hamlet']?.toString() ??
                props['town']?.toString() ??
                '';
            final street =
                props['street']?.toString() ?? props['name']?.toString() ?? '';
            final houseNumber = props['housenumber']?.toString() ?? '';

            final cleanStreet = _cleanStreetName(street);
            final displayParts = <String>[];
            if (ward.isNotEmpty) displayParts.add(ward);
            if (district.isNotEmpty) displayParts.add(district);
            if (city.isNotEmpty) displayParts.add(city);

            return OsmAddress(
              province: resolveOld63Province(
                city,
                district,
                provinceHint: provinceHint,
              ),
              district: district,
              ward: ward,
              street: cleanStreet,
              houseNumber: houseNumber,
              displayAddress: displayParts.join(', '),
            );
          }
        }
      } catch (e2) {} // ignore: empty_catches

      // ─── FALLBACK 2: Gọi BigDataCloud API Reverse Geocode ───
      try {
        final bdcRes = await Dio().get(
          'https://api.bigdatacloud.net/data/reverse-geocode-client',
          queryParameters: {
            'latitude': lat,
            'longitude': lon,
            'localityLanguage': 'vi',
          },
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        if (bdcRes.data != null && bdcRes.data['city'] != null) {
          final data = bdcRes.data;
          final city =
              data['city']?.toString() ??
              data['principalSubdivision']?.toString() ??
              '';
          final district = data['locality']?.toString() ?? '';
          final displayAddress = '$district, $city';

          return OsmAddress(
            province: resolveOld63Province(city, district),
            district: district,
            ward: '',
            street: '',
            houseNumber: '',
            displayAddress: displayAddress,
          );
        }
      } catch (e) {} // ignore: empty_catches

      return null;
    }
  }

  // ─── OFFLINE DISTANCE CALCULATION ────────────────────────────────────────
  /// Tính khoảng cách đường chim bay giữa 2 tọa độ (trả về km) dùng công thức Haversine.
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    const c = cos;
    final a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R (R = 6371 km)
  }

  // ─── AUTOCOMPLETE / DEBOUNCE ─────────────────────────────────────────────
  Timer? _debounceTimer;

  /// Goi y dia chi voi debounce 400ms de tranh spam API.
  void getSuggestionsDebounced(
    String query,
    void Function(List<OsmSuggestion>) onResult,
  ) {
    _debounceTimer?.cancel();
    if (query.trim().length < 3) {
      onResult([]);
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final results = await searchAddress(query, limit: 5);
      onResult(results);
    });
  }

  void cancelDebounce() => _debounceTimer?.cancel();

  // ─── FUZZY MATCH (Tinh / Quan / Phuong) ──────────────────────────────────
  /// Xoa dau tieng Viet va chuan hoa chuoi de so sanh.
  static String normalize(String str) {
    const withDia =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    const withDiaOrig =
        'áàảãạâấầẩẫậăắằẳẵặéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ'
        'ÁÀẢẠÂẤẦẨẪẬĂẮẰẲẴẶÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ';
    String result = str;
    for (int i = 0; i < withDiaOrig.length; i++) {
      result = result.replaceAll(withDiaOrig[i], withDia[i]);
    }
    return result
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'(thanh pho |tp |tinh |quan |huyen |thi xa |phuong |xa |thi tran )',
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Khop mo chuoi a va b sau khi chuan hoa.
  static bool fuzzyMatch(String a, String b) {
    final na = normalize(a);
    final nb = normalize(b);
    return na == nb || na.contains(nb) || nb.contains(na);
  }

  /// Tim phan tu phu hop nhat trong [items] (dang Map co truong 'name')
  /// voi chuoi [rawName].
  static Map<String, dynamic>? findBest(List<dynamic> items, String rawName) {
    if (rawName.isEmpty || items.isEmpty) return null;
    final normalized = normalize(rawName);
    // Exact match first
    for (final item in items) {
      if (normalize(item['name'] as String) == normalized) {
        return item as Map<String, dynamic>;
      }
    }
    // Contains match
    for (final item in items) {
      final n = normalize(item['name'] as String);
      if (n.contains(normalized) || normalized.contains(n)) {
        return item as Map<String, dynamic>;
      }
    }
    return null;
  }

  // ─── OVERPASS API FOR POI DISCOVERY ──────────────────────────────────────
  /// Tim cac diem dang chu y (POIs) xung quanh toa do bang Overpass API
  Future<List<Map<String, dynamic>>> fetchNearbyPOIs(
    double lat,
    double lon, {
    int radius = 2000,
  }) async {
    final overpassQuery =
        '''
      [out:json][timeout:10];
      (
        node["amenity"~"school|university|college|hospital|clinic|bus_station|marketplace"](around:$radius,$lat,$lon);
        node["shop"~"convenience|supermarket|mall"](around:$radius,$lat,$lon);
        node["leisure"~"park"](around:$radius,$lat,$lon);
        way["amenity"~"school|university|college|hospital|clinic|bus_station|marketplace"](around:$radius,$lat,$lon);
        way["shop"~"convenience|supermarket|mall"](around:$radius,$lat,$lon);
        way["leisure"~"park"](around:$radius,$lat,$lon);
      );
      out center 50;
    ''';

    final encodedQuery = Uri.encodeComponent(overpassQuery);
    final endpoints = [
      'https://overpass-api.de/api/interpreter',
      'https://overpass.kumi.systems/api/interpreter',
      'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
    ];

    for (final endpoint in endpoints) {
      try {
        final res = await Dio().post(
          endpoint,
          data: 'data=$encodedQuery',
          options: Options(
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'User-Agent':
                  'StayHubApp/1.0 (rental management; contact@stayhub.vn)',
            },
          ),
        );

        if (res.data == null || res.data['elements'] == null) continue;

        // BUGFIX (data): tránh `as List` ném TypeError khi `elements`
        // không phải List — coerce an toàn.
        final rawElements = res.data['elements'];
        final elements = rawElements is List ? rawElements : const <dynamic>[];
        final results = <Map<String, dynamic>>[];

        for (final el in elements) {
          final tags = el['tags'] as Map? ?? {};
          final name = tags['name']?.toString() ?? tags['brand']?.toString();
          if (name == null || name.isEmpty) continue;

          String category = 'Khác';
          if (tags['amenity'] != null) {
            final am = tags['amenity'];
            if (am == 'school' || am == 'university' || am == 'college') {
              category = 'Giáo dục';
            } else if (am == 'hospital' || am == 'clinic') {
              category = 'Y tế';
            } else if (am == 'bus_station') {
              category = 'Giao thông';
            } else if (am == 'marketplace') {
              category = 'Mua sắm';
            }
          } else if (tags['shop'] != null) {
            category = 'Mua sắm';
          } else if (tags['leisure'] == 'park') {
            category = 'Giải trí';
          }

          final elLat = (el['lat'] ?? el['center']?['lat']);
          final elLon = (el['lon'] ?? el['center']?['lon']);
          double distance = 0;
          if (elLat != null && elLon != null) {
            distance = calculateDistance(
              lat,
              lon,
              (elLat as num).toDouble(),
              (elLon as num).toDouble(),
            );
          }

          results.add({
            'name': name,
            'category': category,
            'distanceKm': distance,
            'lat': elLat,
            'lon': elLon,
          });
        }

        results.sort((a, b) {
          int getPriority(String cat) {
            if (cat == 'Giáo dục') return 1;
            if (cat == 'Y tế') return 2;
            if (cat == 'Giao thông') return 3;
            if (cat == 'Mua sắm') return 4;
            if (cat == 'Giải trí') return 5;
            return 6;
          }

          // BUGFIX (data): tránh `as String`/`as double` ném TypeError khi
          // category/distanceKm null hoặc sai kiểu (int/String từ JSON).
          int pA = getPriority((a['category'] ?? '').toString());
          int pB = getPriority((b['category'] ?? '').toString());
          if (pA != pB) return pA.compareTo(pB);
          final da = a['distanceKm'];
          final db = b['distanceKm'];
          final daD = da is num ? da.toDouble() : 0.0;
          final dbD = db is num ? db.toDouble() : 0.0;
          return daD.compareTo(dbD);
        });

        final seenNames = <String>{};
        final uniqueResults = <Map<String, dynamic>>[];
        for (final r in results) {
          if (!seenNames.contains(r['name'])) {
            seenNames.add(r['name']);
            uniqueResults.add(r);
          }
        }

        return uniqueResults;
      } catch (e) {
        // If it fails, continue to the next endpoint
        continue;
      }
    }

    // ─── FALLBACK: Gọi Photon API nếu tất cả Overpass endpoints đều lỗi ───
    final fallbackResults = <Map<String, dynamic>>[];
    try {
      final queries = [
        {'q': 'school', 'cat': 'Giáo dục'},
        {'q': 'hospital', 'cat': 'Y tế'},
        {'q': 'market', 'cat': 'Mua sắm'},
      ];

      for (final q in queries) {
        final res = await Dio().get(
          '$_photonBase/api/',
          queryParameters: {'q': q['q'], 'lat': lat, 'lon': lon, 'limit': 15},
          options: Options(
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 8),
          ),
        );
        if (res.data != null && res.data['features'] != null) {
          for (final f in res.data['features']) {
            final props = f['properties'] as Map? ?? {};
            final name = props['name']?.toString();
            if (name == null || name.isEmpty) continue;

            final coords = f['geometry']?['coordinates'] as List? ?? [0.0, 0.0];
            final elLon = double.tryParse(coords[0].toString()) ?? 0.0;
            final elLat = double.tryParse(coords[1].toString()) ?? 0.0;
            double distance = calculateDistance(lat, lon, elLat, elLon);
            if (distance > radius / 1000.0) {
              continue; // Bỏ qua nếu xa hơn bán kính
            }

            fallbackResults.add({
              'name': name,
              'category': q['cat'],
              'distanceKm': distance,
              'lat': elLat,
              'lon': elLon,
            });
          }
        }
      }
    } catch (_) {}

    return fallbackResults;
  }
}

// ─── PROVIDERS ───────────────────────────────────────────────────────────────
final osmMapServiceProvider = Provider<OsmMapService>((ref) => OsmMapService());
