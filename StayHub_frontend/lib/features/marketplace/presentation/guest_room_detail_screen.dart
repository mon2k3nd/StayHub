import 'package:flutter/cupertino.dart';

import 'widgets/guest_room_detail_premium.dart';

/// Full-screen version of the room detail, used when navigating to
/// the '/guest-room-detail' route (e.g., from login redirect or deep links).
class GuestRoomDetailScreen extends StatefulWidget {
  final int? roomId;
  final Map<String, dynamic> room;

  const GuestRoomDetailScreen({super.key, this.roomId, this.room = const {}});

  @override
  State<GuestRoomDetailScreen> createState() => _GuestRoomDetailScreenState();
}

class _GuestRoomDetailScreenState extends State<GuestRoomDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GuestRoomDetailPremiumBottomSheet(
      room: widget.room,
      roomId: widget.roomId,
      scrollController: _scrollController,
      isFullScreen: true,
    );
  }
}
