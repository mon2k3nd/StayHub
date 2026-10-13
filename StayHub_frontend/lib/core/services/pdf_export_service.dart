import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfExportService {
  static Future<Uint8List> generateOfflineContractPdf({
    required String ownerName,
    required String ownerPhone,
    required String tenantName,
    required String tenantPhone,
    required String tenantCccd,
    required String roomName,
    required String address,
    required double rentAmount,
    required double depositAmount,
    required double electricityPrice,
    required double waterPrice,
    required DateTime startDate,
    required DateTime endDate,
    required double initialElectricity,
    required double initialWater,
    String? customTerms,
  }) async {
    final pdf = pw.Document();

    // Load font for Vietnamese
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VNĐ',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          // Tiêu đề
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'CỘNG HOÀ XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                  style: const pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.Text(
                  'Độc lập - Tự do - Hạnh phúc',
                  style: const pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'HỢP ĐỒNG THUÊ PHÒNG',
                  style: const pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                pw.Text(
                  'VÀ BIÊN BẢN BÀN GIAO',
                  style: const pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
            ),
          ),

          // Bên A
          pw.Text(
            'BÊN A (BÊN CHO THUÊ):',
            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Bullet(text: 'Họ và tên: $ownerName'),
          pw.Bullet(text: 'Số điện thoại: $ownerPhone'),
          pw.SizedBox(height: 10),

          // Bên B
          pw.Text(
            'BÊN B (BÊN THUÊ):',
            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Bullet(text: 'Họ và tên: $tenantName'),
          pw.Bullet(text: 'Số điện thoại: $tenantPhone'),
          pw.Bullet(text: 'CCCD/CMND: $tenantCccd'),
          pw.SizedBox(height: 20),

          // Điều khoản
          pw.Text(
            'Hai bên thống nhất ký kết hợp đồng cho thuê nhà ở với các nội dung sau đây:',
            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.Text(
            'Điều 1. Các thông tin về nhà ở cho thuê',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.Text('- Phòng: $roomName'),
          pw.Text('- Địa chỉ (Chuẩn pháp lý): $address'),
          pw.SizedBox(height: 10),

          pw.Text(
            'Điều 2. Giá thuê nhà ở',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.Text(
            '- Giá thuê hàng tháng: ${currencyFormat.format(rentAmount)}',
          ),
          pw.Text(
            '- Giá thuê trên đã bao gồm chi phí quản lý vận hành theo thỏa thuận giữa hai bên.',
          ),
          pw.Text(
            'Các chi phí sử dụng điện, nước và dịch vụ khác do Bên B thanh toán theo mức thỏa thuận sau:',
          ),
          pw.Text(
            '- Giá điện: ${currencyFormat.format(electricityPrice)} /kWh',
          ),
          pw.Text(
            '- Giá nước: ${currencyFormat.format(waterPrice)} /khối (hoặc người)',
          ),
          pw.SizedBox(height: 10),

          pw.Text(
            'Điều 3. Phương thức và thời hạn thanh toán',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.Text(
            '1. Phương thức thanh toán: Thanh toán bằng tiền Việt Nam thông qua hình thức chuyển khoản qua ngân hàng hoặc hình thức khác theo thỏa thuận.',
          ),
          pw.Text('2. Thời hạn thanh toán: Trước ngày 05 hàng tháng.'),
          pw.SizedBox(height: 10),

          pw.Text(
            'Điều 4. Thời hạn cho thuê và tiền cọc',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          pw.Text(
            '- Thời hạn thuê từ ngày ${dateFormat.format(startDate)} đến ngày ${dateFormat.format(endDate)}.',
          ),
          pw.Text('- Tiền đặt cọc: ${currencyFormat.format(depositAmount)}'),
          pw.Text(
            '- Tiền cọc sẽ được hoàn trả khi Bên B trả phòng và không vi phạm hợp đồng, sau khi trừ đi chi phí hư hỏng (nếu có).',
          ),
          pw.SizedBox(height: 10),

          if (customTerms != null && customTerms.isNotEmpty)
            ...() {
              try {
                final decoded = jsonDecode(customTerms) as List;
                return decoded.map((e) {
                  final item = e as Map<String, dynamic>;
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        item['title'] ?? '',
                        style: const pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                      pw.Text(item['content'] ?? ''),
                      pw.SizedBox(height: 10),
                    ],
                  );
                }).toList();
              } catch (e, st) {
                debugPrint('Error: $e\n$st');
                // Fallback for plain text
                return [pw.Text(customTerms)];
              }
            }()
          else ...[
            pw.Text(
              'Điều 5. Quyền và nghĩa vụ của Bên cho thuê (Bên A)',
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.Text(
              '1. Giao nhà ở cho Bên B đúng hiện trạng và hướng dẫn sử dụng.',
            ),
            pw.Text(
              '2. Bảo đảm cho Bên B sử dụng ổn định trong thời hạn thuê.',
            ),
            pw.Text(
              '3. Bảo trì, sửa chữa nhà ở theo định kỳ; bồi thường nếu không bảo trì gây thiệt hại.',
            ),
            pw.Text(
              '4. Không được đơn phương chấm dứt hợp đồng khi Bên B thực hiện đúng nghĩa vụ.',
            ),
            pw.Text(
              '5. Thực hiện nghĩa vụ tài chính với Nhà nước theo quy định pháp luật.',
            ),
            pw.SizedBox(height: 10),

            pw.Text(
              'Điều 6. Quyền và nghĩa vụ của Bên thuê (Bên B)',
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.Text('1. Yêu cầu Bên A giao nhà đúng hiện trạng đã thỏa thuận.'),
            pw.Text('2. Bảo quản, sử dụng nhà ở đúng công năng, thiết kế.'),
            pw.Text(
              '3. Thanh toán đủ tiền thuê theo thời hạn và phương thức đã thỏa thuận.',
            ),
            pw.Text(
              '4. Không được thay đổi, cải tạo, phá dỡ nếu không có sự đồng ý bằng văn bản của Bên A.',
            ),
            pw.Text('5. Trả nhà ở cho Bên A khi hết thời hạn thuê.'),
            pw.Text('6. Bồi thường thiệt hại do lỗi của mình gây ra.'),
            pw.SizedBox(height: 10),

            pw.Text(
              'Điều 7. Trách nhiệm do vi phạm hợp đồng',
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.Text(
              '1. Bên vi phạm phải bồi thường thiệt hại cho bên còn lại theo quy định pháp luật.',
            ),
            pw.Text(
              '2. Trường hợp bất khả kháng (thiên tai, chiến tranh, thay đổi quy định pháp luật) không bị coi là vi phạm hợp đồng.',
            ),
            pw.SizedBox(height: 10),

            pw.Text(
              'Điều 8. Các trường hợp chấm dứt hợp đồng',
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.Text('1. Hai bên đồng ý chấm dứt hợp đồng bằng văn bản.'),
            pw.Text('2. Bên B chậm thanh toán tiền thuê quá 30 ngày.'),
            pw.Text('3. Bên A chậm bàn giao nhà ở theo thỏa thuận.'),
            pw.Text(
              '4. Sự kiện bất khả kháng không thể khắc phục trong 90 ngày.',
            ),
            pw.SizedBox(height: 10),

            pw.Text(
              'Điều 9. Giải quyết tranh chấp',
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.Text(
              'Mọi tranh chấp phát sinh từ hợp đồng này trước hết được giải quyết thông qua thương lượng, hòa giải giữa hai bên. Trường hợp không thể giải quyết được thì đưa ra Tòa án nhân dân có thẩm quyền theo quy định pháp luật.',
            ),
            pw.SizedBox(height: 10),

            pw.Text(
              'Điều 10. Hiệu lực của hợp đồng',
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.Text('1. Hợp đồng này có hiệu lực kể từ ngày hai bên ký kết.'),
            pw.Text(
              '2. Hợp đồng này được lập thành 02 bản có giá trị pháp lý như nhau, mỗi bên giữ 01 bản.',
            ),
            pw.Text(
              '3. Các phụ lục đính kèm là nội dung không tách rời hợp đồng này.',
            ),
            pw.SizedBox(height: 10),
          ],

          pw.Text(
            'BIÊN BẢN BÀN GIAO THIẾT BỊ',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text('Hiện trạng chỉ số dịch vụ tại thời điểm bàn giao:'),
          pw.Text('- Chỉ số điện: $initialElectricity'),
          pw.Text('- Chỉ số nước: $initialWater'),
          pw.SizedBox(height: 20),

          // Ký tên
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'ĐẠI DIỆN BÊN A',
                    style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '(Ký, ghi rõ họ tên)',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 60),
                  pw.Text(ownerName),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'ĐẠI DIỆN BÊN B',
                    style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '(Ký, ghi rõ họ tên)',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 60),
                  pw.Text(tenantName),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static Future<Uint8List> generateFinancialReportPdf({
    required List<dynamic> bills,
    required DateTime startDate,
    required DateTime endDate,
    String? branchName,
  }) async {
    final pdf = pw.Document();

    // Load font for Vietnamese
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VNĐ',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    double totalRevenue = 0;
    double totalRent = 0;
    double totalElec = 0;
    double totalWater = 0;

    for (var b in bills) {
      if (b.status == 'PAID') {
        totalRevenue += (b.totalAmount ?? 0);
        totalRent += (b.rentAmount ?? 0);
        totalElec += (b.electricAmount ?? 0);
        totalWater += (b.waterAmount ?? 0);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          // Tiêu đề
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'BÁO CÁO TÀI CHÍNH KẾ TOÁN (THU/CHI)',
                  style: const pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Thời gian: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                if (branchName != null)
                  pw.Text(
                    'Dãy trọ: $branchName',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                pw.SizedBox(height: 30),
              ],
            ),
          ),

          // Summary Cards
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TỔNG DOANH THU ĐÃ THU',
                      style: const pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      currencyFormat.format(totalRevenue),
                      style: const pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                        color: PdfColors.blue700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TIỀN PHÒNG',
                      style: const pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      currencyFormat.format(totalRent),
                      style: const pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ĐIỆN & NƯỚC',
                      style: const pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      currencyFormat.format(totalElec + totalWater),
                      style: const pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),

          pw.Text(
            'CHI TIẾT HÓA ĐƠN:',
            style: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
          pw.SizedBox(height: 10),

          // Table
          pw.TableHelper.fromTextArray(
            headers: [
              'STT',
              'Kỳ',
              'Phòng',
              'Tổng Thu',
              'Trạng Thái',
              'Ngày Thu',
            ],
            data: List<List<String>>.generate(bills.length, (index) {
              final b = bills[index];
              final isPaid = b.status == 'PAID';
              return [
                (index + 1).toString(),
                b.periodLabel,
                'Phòng ${b.roomId}',
                currencyFormat.format(b.totalAmount ?? 0),
                isPaid ? 'Đã thu' : 'Chưa thu',
                b.paidAt != null ? dateFormat.format(b.paidAt!) : '',
              ];
            }),
            headerStyle: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
          ),

          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Ngày ..... tháng ..... năm 20.....',
                    style: const pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Người lập báo cáo',
                    style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    '(Ký, ghi rõ họ tên)',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 60),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  /// Xuất PDF hóa đơn cho một phòng cụ thể
  static Future<Uint8List> generateBillPdf({required dynamic bill}) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    final double totalAmount = bill.totalAmount ?? 0;
    final double rentAmount = bill.rentAmount ?? 0;
    final double electricAmount = bill.electricAmount ?? 0;
    final double waterAmount = bill.waterAmount ?? 0;
    final double serviceAmount = bill.serviceAmount ?? 0;
    final String period = bill.periodLabel ?? 'N/A';
    final bool isPaid = bill.status == 'PAID';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'HÓA ĐƠN TIỀN PHÒNG',
                    style: const pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 22,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Kỳ: $period',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: isPaid ? PdfColors.green100 : PdfColors.red100,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(20),
                      ),
                    ),
                    child: pw.Text(
                      isPaid ? '✓ ĐÃ THANH TOÁN' : '⏳ CHƯA THANH TOÁN',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: isPaid ? PdfColors.green800 : PdfColors.red800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.blue200),
            pw.SizedBox(height: 16),

            // Chi tiết mục
            pw.Text(
              'CHI TIẾT HÓA ĐƠN',
              style: const pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 13,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 12),

            _billRow(
              'Tiền thuê phòng',
              currencyFormat.format(rentAmount),
              fontBold,
              font,
              isHighlight: false,
            ),
            if (electricAmount > 0)
              _billRow(
                'Tiền điện',
                currencyFormat.format(electricAmount),
                fontBold,
                font,
              ),
            if (waterAmount > 0)
              _billRow(
                'Tiền nước',
                currencyFormat.format(waterAmount),
                fontBold,
                font,
              ),
            if (serviceAmount > 0)
              _billRow(
                'Phí dịch vụ khác',
                currencyFormat.format(serviceAmount),
                fontBold,
                font,
              ),

            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.blue800, thickness: 1.5),
            pw.SizedBox(height: 8),

            // Tổng
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TỔNG CỘNG',
                  style: const pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.Text(
                  currencyFormat.format(totalAmount),
                  style: const pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                    color: PdfColors.blue800,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 40),

            // Footer
            pw.Center(
              child: pw.Text(
                'Cảm ơn bạn! Vui lòng thanh toán trước ngày 05 hàng tháng.',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Xuất bởi hệ thống StayHub • ${dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _billRow(
    String label,
    String value,
    pw.Font bold,
    pw.Font regular, {
    bool isHighlight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: regular,
              fontSize: 13,
              color: PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: bold,
              fontSize: 13,
              color: isHighlight ? PdfColors.blue700 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
