import 'package:flutter_test/flutter_test.dart';
import 'package:stayhub_frontend/core/services/osm_map_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('searchSuggestions finds 42 vinh phuc with number extraction', () async {
    final service = OsmMapService();
    final suggestions = await service.searchSuggestions('42 vĩnh phúc');

    expect(suggestions.isNotEmpty, isTrue);
    final first = suggestions.first;
    expect(first.shortName, contains('42'));
    expect(first.shortName.toLowerCase(), contains('vĩnh phúc'));
    expect(first.displayName, contains('Hà Nội'));
    expect(first.latLng.latitude, closeTo(21.0375, 0.01));
    expect(first.latLng.longitude, closeTo(105.8115, 0.01));
  });

  test('searchSuggestions finds doi can without number', () async {
    final service = OsmMapService();
    final suggestions = await service.searchSuggestions('đội cấn');

    expect(suggestions.isNotEmpty, isTrue);
    final match = suggestions.firstWhere(
      (s) => s.shortName.toLowerCase().contains('đội cấn'),
    );
    expect(match.displayName, contains('Ba Đình'));
  });

  test(
    'searchSuggestions for "143 cầu diễn" returns Cau Dien and NEVER Van Dien or Khanh Hoa',
    () async {
      final service = OsmMapService();
      final suggestions = await service.searchSuggestions('143 cầu diễn');

      expect(suggestions.isNotEmpty, isTrue);

      // Không bao giờ được chứa Văn Điển hoặc Khánh Hòa
      for (final s in suggestions) {
        expect(
          s.displayName.toLowerCase().contains('văn điển'),
          isFalse,
          reason: 'Must not suggest Cầu Văn Điển: ${s.displayName}',
        );
        expect(
          s.displayName.toLowerCase().contains('đồng điền'),
          isFalse,
          reason: 'Must not suggest Cầu Đồng Điền: ${s.displayName}',
        );
        expect(
          s.displayName.toLowerCase().contains('khánh hòa'),
          isFalse,
          reason: 'Must not suggest Khánh Hòa: ${s.displayName}',
        );
      }

      // Phải có ít nhất 1 kết quả chính xác về Cầu Diễn
      final match = suggestions.firstWhere(
        (s) => s.shortName.toLowerCase().contains('cầu diễn'),
        orElse: () => throw Exception('Không tìm thấy Cầu Diễn trong kết quả'),
      );
      expect(match.shortName, contains('143'));
      expect(
        match.displayName,
        anyOf(
          contains('Bắc Từ Liêm'),
          contains('Nam Từ Liêm'),
          contains('Hà Nội'),
        ),
      );
      expect(match.latLng.latitude, closeTo(21.04, 0.05));
      expect(match.latLng.longitude, closeTo(105.76, 0.05));
    },
  );

  test('normalizePreservingD preserves difference between d and đ', () {
    final normCauDien = OsmMapService.normalizePreservingD('143 Cầu Diễn');
    final normVanDien = OsmMapService.normalizePreservingD('Cầu Văn Điển');
    final normDongDien = OsmMapService.normalizePreservingD('Cầu Đồng Điền');

    expect(normCauDien, contains('cau dien'));
    expect(normVanDien, contains('cau van đien'));
    expect(normDongDien, contains('cau đong đien'));

    expect(normCauDien.contains('đien'), isFalse);
    expect(normVanDien.contains('dien'), isFalse);
  });

  test(
    'searchSuggestions for "351 cầ" or "351 cả" matches Cầu Giấy / Cầu Diễn and zero Thai characters',
    () async {
      final service = OsmMapService();
      final suggestions = await service.searchSuggestions('351 cầ');

      expect(suggestions.isNotEmpty, isTrue);

      for (final s in suggestions) {
        // Tuyệt đối không được chứa bất kỳ ký tự tiếng Thái nào
        expect(
          OsmMapService.hasNonVietnameseScript(s.displayName),
          isFalse,
          reason: 'Must not contain foreign script: ${s.displayName}',
        );
        expect(
          OsmMapService.hasNonVietnameseScript(s.shortName),
          isFalse,
          reason: 'Must not contain foreign script: ${s.shortName}',
        );
        expect(OsmMapService.isInsideVietnam(s.latLng), isTrue);
      }

      // Phải khớp với Cầu Giấy hoặc Cầu Diễn kèm số nhà 351
      final match = suggestions.firstWhere(
        (s) =>
            s.shortName.toLowerCase().contains('cầu giấy') ||
            s.shortName.toLowerCase().contains('cầu diễn'),
        orElse: () =>
            throw Exception('Không tìm thấy gợi ý Cầu Giấy hoặc Cầu Diễn'),
      );
      expect(match.shortName, contains('351'));
    },
  );

  test('hasNonVietnameseScript rejects Thai and other non-Latin scripts', () {
    expect(OsmMapService.hasNonVietnameseScript('จังหวัดยโสธร'), isTrue);
    expect(
      OsmMapService.hasNonVietnameseScript('351 BD, จังหวัดยโสธร'),
      isTrue,
    );
    expect(
      OsmMapService.hasNonVietnameseScript('351 Đường Cầu Giấy, Hà Nội'),
      isFalse,
    );
  });
}
