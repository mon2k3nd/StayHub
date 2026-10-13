package com.stayhub.api.job;

import com.stayhub.api.entity.AnalyticsFinancialReport;
import com.stayhub.api.repository.AnalyticsFinancialReportRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class AnalyticsCronJob {

    private final AnalyticsFinancialReportRepository analyticsRepo;

    /**
     * Chạy vào lúc 00:05 mỗi ngày để tính toán dữ liệu của ngày hôm qua (ETL process)
     */
    @Scheduled(cron = "0 5 0 * * ?")
    @Transactional
    public void aggregateDailyFinancialReport() {
        LocalDate yesterday = LocalDate.now().minusDays(1);
        log.info("Bắt đầu chạy Cron Job tổng hợp dữ liệu Analytics cho ngày: {}", yesterday);

        try {
            // 1. Kiểm tra xem ngày này đã được chốt sổ chưa
            AnalyticsFinancialReport report = analyticsRepo.findByReportDate(yesterday)
                    .orElse(AnalyticsFinancialReport.builder()
                            .reportDate(yesterday)
                            .reportMonth(yesterday.getMonthValue())
                            .reportYear(yesterday.getYear())
                            .build());

            if (Boolean.TRUE.equals(report.getIsFinalized())) {
                log.warn("Dữ liệu ngày {} đã được finalized, bỏ qua việc chạy lại.", yesterday);
                return;
            }

            // 2. TÍNH TOÁN DỮ LIỆU (Giả lập logic do hệ thống MVP chưa có module payment đầy đủ)
            // Trong thực tế, ở đây sẽ có các query dạng: billRepository.sumRevenueByDate(...)
            
            // Giả lập tính toán doanh thu (Random để có số liệu demo trên biểu đồ)
            long mockDailyRevenue = 500000 + (long)(Math.random() * 2000000); 
            long mockSaasRev = (long)(mockDailyRevenue * 0.8);
            long mockComRev = mockDailyRevenue - mockSaasRev;

            report.setTotalRevenue(BigDecimal.valueOf(mockDailyRevenue));
            report.setSaasRevenue(BigDecimal.valueOf(mockSaasRev));
            report.setCommissionRevenue(BigDecimal.valueOf(mockComRev));

            // Cập nhật số lượng gói bán
            report.setFreePackagesSold(5 + (int)(Math.random() * 5));
            report.setBasicPackagesSold(2 + (int)(Math.random() * 3));
            report.setProPackagesSold(1 + (int)(Math.random() * 2));
            report.setEnterprisePackagesSold(0);

            // Cập nhật thông tin churn/risk
            report.setChurnedOwnersCount((int)(Math.random() * 3));
            report.setAtRiskOwnersCount((int)(Math.random() * 5));

            // 3. Đánh dấu hoàn tất
            report.setLastRunAt(LocalDateTime.now());
            // Chỉ finalize nếu đã chắc chắn dữ liệu không đổi (Ví dụ: Chạy vào cuối tháng)
            // Ở đây tạm set finalized = true để tránh duplicate nếu chạy lại trong ngày
            report.setIsFinalized(true); 

            analyticsRepo.save(report);
            log.info("Cron Job tổng hợp dữ liệu ngày {} đã hoàn thành công.", yesterday);

        } catch (Exception e) {
            log.error("Lỗi nghiêm trọng khi chạy Cron Job Analytics ngày {}: {}", yesterday, e.getMessage(), e);
            // Có thể gửi cảnh báo qua Slack/Email ở đây
        }
    }
    
    /**
     * Chạy ngay lập tức khi khởi động app để tạo dữ liệu demo 7 ngày gần nhất
     * (Chỉ dùng cho môi trường Dev)
     */
    @Transactional
    public void generateMockDataForLast7Days() {
        for (int i = 7; i >= 1; i--) {
            LocalDate date = LocalDate.now().minusDays(i);
            if (analyticsRepo.findByReportDate(date).isEmpty()) {
                AnalyticsFinancialReport report = AnalyticsFinancialReport.builder()
                        .reportDate(date)
                        .reportMonth(date.getMonthValue())
                        .reportYear(date.getYear())
                        .totalRevenue(BigDecimal.valueOf(1000000 + Math.random() * 3000000))
                        .saasRevenue(BigDecimal.valueOf(800000 + Math.random() * 2000000))
                        .freePackagesSold((int)(Math.random() * 10))
                        .basicPackagesSold((int)(Math.random() * 5))
                        .proPackagesSold((int)(Math.random() * 3))
                        .isFinalized(true)
                        .lastRunAt(LocalDateTime.now())
                        .build();
                analyticsRepo.save(report);
            }
        }
    }
}
