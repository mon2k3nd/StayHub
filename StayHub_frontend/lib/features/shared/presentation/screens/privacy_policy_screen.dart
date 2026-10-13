import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/glass_container.dart';

/// Màn hình Chính sách bảo mật & Điều khoản sử dụng
/// Tuân thủ NĐ 13/2023/NĐ-CP về bảo vệ dữ liệu cá nhân
class PrivacyPolicyScreen extends StatelessWidget {
  final bool showTerms;
  const PrivacyPolicyScreen({super.key, this.showTerms = false});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          showTerms ? 'Điều Khoản Sử Dụng' : 'Chính Sách Bảo Mật',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  showTerms ? _termsItems() : _privacyItems(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _privacyItems() => [
    _header(
      '🛡️ Chính Sách Bảo Mật',
      'Cập nhật: 01/07/2025 — Tuân thủ NĐ 13/2023/NĐ-CP',
    ),
    _section('1. Thông tin chúng tôi thu thập', [
      'Họ tên, số điện thoại, email khi đăng ký tài khoản',
      'Thông tin phòng trọ do chủ nhà tự đăng tải',
      'Lịch sử tìm kiếm và yêu thích phòng (lưu trên thiết bị)',
      'Thông tin thiết bị và hệ điều hành (phục vụ cải thiện app)',
    ]),
    _section('2. Mục đích sử dụng', [
      'Cung cấp dịch vụ kết nối người thuê và chủ nhà',
      'Gửi thông báo liên quan đến hợp đồng, hóa đơn',
      'Cải thiện chất lượng ứng dụng',
      'Tuân thủ nghĩa vụ pháp lý',
    ]),
    _section('3. Bảo vệ thông tin cá nhân', [
      'Số điện thoại chủ nhà được ẩn với người chưa đăng nhập',
      'CMND/CCCD chỉ dùng để xác minh, không chia sẻ với bên thứ 3',
      'Dữ liệu được mã hóa SSL/TLS khi truyền tải',
      'Không bán hoặc cho thuê thông tin cá nhân của bạn',
    ]),
    _section('4. Quyền của người dùng', [
      'Quyền truy cập và xem lại thông tin cá nhân của mình',
      'Quyền yêu cầu chỉnh sửa thông tin không chính xác',
      'Quyền yêu cầu xóa tài khoản và toàn bộ dữ liệu',
      'Quyền rút lại sự đồng ý thu thập dữ liệu bất kỳ lúc nào',
    ]),
    _section('5. Liên hệ', [
      'Email: privacy@stayhub.vn',
      'Hotline: 1800-xxxx (miễn phí)',
      'Địa chỉ: Hà Nội, Việt Nam',
    ]),
  ];

  List<Widget> _termsItems() => [
    _header('📋 Điều Khoản Sử Dụng', 'Cập nhật: 01/07/2025'),
    _section('1. Điều kiện sử dụng', [
      'Người dùng phải từ 18 tuổi trở lên',
      'Cung cấp thông tin trung thực khi đăng ký',
      'Xác thực số điện thoại trước khi đăng bài',
      'Mỗi số điện thoại chỉ được tạo 1 tài khoản',
    ]),
    _section('2. Quy định đăng tin cho chủ nhà', [
      'Chỉ đăng phòng/nhà mà bạn là chủ sở hữu hợp pháp',
      'Thông tin giá, diện tích, tiện ích phải trung thực',
      'Ảnh phòng phải là ảnh thực tế, không chỉnh sửa quá mức',
      'Nghiêm cấm đăng tin lừa đảo, gây hiểu nhầm',
    ]),
    _section('3. Trách nhiệm người dùng', [
      'Giữ bảo mật tài khoản, không chia sẻ mật khẩu',
      'Không sử dụng app cho mục đích vi phạm pháp luật',
      'Tuân thủ Luật Kinh doanh Bất động sản 2023',
      'Báo cáo ngay khi phát hiện nội dung vi phạm',
    ]),
    _section('4. Giới hạn trách nhiệm', [
      'StayHub là nền tảng kết nối, không phải bên ký hợp đồng',
      'Chúng tôi không chịu trách nhiệm về tranh chấp giữa 2 bên',
      'Người dùng tự chịu trách nhiệm về giao dịch của mình',
    ]),
  ];

  Widget _header(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.kAccentColor,
                AppTheme.kAccentColor.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    ),
  );

  Widget _section(String title, List<String> items) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.kAccentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
