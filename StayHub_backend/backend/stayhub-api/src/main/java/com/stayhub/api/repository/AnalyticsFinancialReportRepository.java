package com.stayhub.api.repository;

import com.stayhub.api.entity.AnalyticsFinancialReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface AnalyticsFinancialReportRepository extends JpaRepository<AnalyticsFinancialReport, Long> {
    
    Optional<AnalyticsFinancialReport> findByReportDate(LocalDate reportDate);
    
    List<AnalyticsFinancialReport> findByReportDateBetweenOrderByReportDateAsc(LocalDate startDate, LocalDate endDate);
}
