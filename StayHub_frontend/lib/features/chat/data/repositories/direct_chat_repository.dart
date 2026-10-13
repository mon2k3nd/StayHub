import 'package:dio/dio.dart';
import '../models/direct_chat_message_model.dart';

class DirectChatRepository {
  final Dio dio;

  DirectChatRepository(this.dio);

  Future<List<DirectChatMessageModel>> getHistory(
    int myUserId,
    int partnerId,
  ) async {
    final response = await dio.get(
      '/v1/direct-chat/history',
      queryParameters: {'partnerId': partnerId},
      options: Options(headers: {'X-User-Id': myUserId}),
    );
    if (response.data is List) {
      // BUGFIX (Bug 116): tránh cast cứng `e as Map<String, dynamic>` — nếu
      // phần tử không phải Map (null/kiểu khác) sẽ ném TypeError làm hỏng cả
      // lịch sử chat. Lọc an toàn bằng whereType.
      return (response.data as List)
          .whereType<Map>()
          .map(
            (e) =>
                DirectChatMessageModel.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }
    return [];
  }

  Future<DirectChatMessageModel> sendMessage(
    int senderId,
    Map<String, dynamic> request,
  ) async {
    final response = await dio.post(
      '/v1/direct-chat/send',
      data: request,
      options: Options(headers: {'X-User-Id': senderId}),
    );
    // BUGFIX (Bug 116): tránh cast cứng `response.data as Map<String, dynamic>`
    // — nếu backend trả null/kiểu khác sẽ ném TypeError. Trả về model rỗng an
    // toàn thay vì crash.
    final data = response.data;
    if (data is Map) {
      return DirectChatMessageModel.fromJson(Map<String, dynamic>.from(data));
    }
    return const DirectChatMessageModel(
      senderId: 0,
      receiverId: 0,
      content: '',
    );
  }
}
