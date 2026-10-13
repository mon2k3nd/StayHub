import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:intl/intl.dart';
import '../../features/bill/data/models/bill_model.dart';

class ExcelExportService {
  static Future<String?> generateFinancialReportExcel({
    required List<BillModel> bills,
    required DateTime startDate,
    required DateTime endDate,
    String? branchName,
  }) async {
    try {
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Báo Cáo Thu Chi';

      // Formatting
      final Style titleStyle = workbook.styles.add('TitleStyle');
      titleStyle.fontSize = 16;
      titleStyle.bold = true;
      titleStyle.hAlign = HAlignType.center;

      final Style headerStyle = workbook.styles.add('HeaderStyle');
      headerStyle.bold = true;
      headerStyle.backColor = '#0EA5E9'; // Sky Blue
      headerStyle.fontColor = '#FFFFFF';
      headerStyle.hAlign = HAlignType.center;
      headerStyle.borders.all.lineStyle = LineStyle.thin;
      headerStyle.borders.all.color = '#000000';

      final Style dataStyle = workbook.styles.add('DataStyle');
      dataStyle.borders.all.lineStyle = LineStyle.thin;
      dataStyle.borders.all.color = '#DDDDDD';

      final dateFmt = DateFormat('dd/MM/yyyy');

      // Add Title
      sheet.getRangeByName('A1:J1').merge();
      sheet.getRangeByName('A1').text = 'BÁO CÁO TÀI CHÍNH KẾ TOÁN (THU/CHI)';
      sheet.getRangeByName('A1').cellStyle = titleStyle;

      sheet.getRangeByName('A2:J2').merge();
      sheet.getRangeByName('A2').text =
          'Thời gian: ${dateFmt.format(startDate)} - ${dateFmt.format(endDate)}';
      sheet.getRangeByName('A2').cellStyle.hAlign = HAlignType.center;

      if (branchName != null) {
        sheet.getRangeByName('A3:J3').merge();
        sheet.getRangeByName('A3').text = 'Dãy trọ: $branchName';
        sheet.getRangeByName('A3').cellStyle.hAlign = HAlignType.center;
      }

      // Headers
      const int headerRow = 5;
      final headers = [
        'STT',
        'Kỳ Hóa Đơn',
        'Phòng',
        'Tiền Thuê (VNĐ)',
        'Tiền Điện (VNĐ)',
        'Tiền Nước (VNĐ)',
        'Phí Dịch Vụ (VNĐ)',
        'Tổng Thu (VNĐ)',
        'Trạng Thái',
        'Ngày Thu',
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(headerRow, i + 1).text = headers[i];
        sheet.getRangeByIndex(headerRow, i + 1).cellStyle = headerStyle;
        sheet.setColumnWidthInPixels(i + 1, 120);
      }
      sheet.setColumnWidthInPixels(1, 50); // STT column width

      // Data
      int row = headerRow + 1;
      double totalRent = 0;
      double totalElec = 0;
      double totalWater = 0;
      double totalService = 0;
      double totalRevenue = 0;

      for (int i = 0; i < bills.length; i++) {
        final b = bills[i];
        sheet.getRangeByIndex(row, 1).number = (i + 1).toDouble();
        sheet.getRangeByIndex(row, 2).text = b.periodLabel;
        sheet.getRangeByIndex(row, 3).text = 'Phòng ${b.roomId}';
        sheet.getRangeByIndex(row, 4).number = b.rentAmount ?? 0;
        sheet.getRangeByIndex(row, 5).number = b.electricAmount ?? 0;
        sheet.getRangeByIndex(row, 6).number = b.waterAmount ?? 0;
        sheet.getRangeByIndex(row, 7).number = b.serviceAmount ?? 0;
        sheet.getRangeByIndex(row, 8).number = b.totalAmount ?? 0;
        sheet.getRangeByIndex(row, 9).text = b.status == 'PAID'
            ? 'Đã thu'
            : 'Chưa thu';
        sheet.getRangeByIndex(row, 10).text = b.paidAt != null
            ? dateFmt.format(b.paidAt!)
            : '';

        for (int col = 1; col <= 10; col++) {
          sheet.getRangeByIndex(row, col).cellStyle = dataStyle;
        }

        if (b.status == 'PAID') {
          totalRent += b.rentAmount ?? 0;
          totalElec += b.electricAmount ?? 0;
          totalWater += b.waterAmount ?? 0;
          totalService += b.serviceAmount ?? 0;
          totalRevenue += b.totalAmount ?? 0;
        }

        row++;
      }

      // Summary
      row++;
      sheet.getRangeByIndex(row, 1, row, 3).merge();
      sheet.getRangeByIndex(row, 1).text = 'TỔNG CỘNG ĐÃ THU:';
      sheet.getRangeByIndex(row, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(row, 1).cellStyle.hAlign = HAlignType.right;

      sheet.getRangeByIndex(row, 4).number = totalRent;
      sheet.getRangeByIndex(row, 5).number = totalElec;
      sheet.getRangeByIndex(row, 6).number = totalWater;
      sheet.getRangeByIndex(row, 7).number = totalService;
      sheet.getRangeByIndex(row, 8).number = totalRevenue;

      for (int col = 4; col <= 8; col++) {
        sheet.getRangeByIndex(row, col).cellStyle.bold = true;
        sheet.getRangeByIndex(row, col).cellStyle.fontColor = '#0EA5E9';
      }

      // Save file
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      Directory? directory;
      if (Platform.isWindows) {
        final docs = await getApplicationDocumentsDirectory();
        directory = docs;
      } else if (Platform.isAndroid || Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory =
            await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String path = '${directory.path}/BaoCaoThuChi_$timestamp.xlsx';
      final File file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      return path;
    } catch (e) {
      debugPrint('Lỗi xuất Excel: $e');
      return null;
    }
  }
}
