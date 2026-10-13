import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/core_providers.dart';
import '../models/audit_log_model.dart';

final auditLogsProvider =
    FutureProvider.family<
      List<AuditLogModel>,
      ({String entityType, int entityId})
    >((ref, args) async {
      final dio = ref.read(dioProvider);
      final res = await dio.get(
        '/v1/audit-logs/${args.entityType}/${args.entityId}',
      );
      // BUGFIX (data): tránh `as List` ném TypeError khi body không phải List —
      // lọc an toàn bằng whereType.
      final raw = res.data;
      if (raw is! List) return <AuditLogModel>[];
      // BUGFIX (data): whereType<Map>() trả Map<dynamic,dynamic> — cần ép về
      // Map<String,dynamic> để khớp fromJson.
      return raw
          .whereType<Map>()
          .map((e) => AuditLogModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    });
