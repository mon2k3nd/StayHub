package com.stayhub.api.repository;

import com.stayhub.api.entity.AnalyticsRiskReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface AnalyticsRiskReportRepository extends JpaRepository<AnalyticsRiskReport, Long> {
    
    Optional<AnalyticsRiskReport> findByReportDate(LocalDate reportDate);
    
    List<AnalyticsRiskReport> findByReportDateBetweenOrderByReportDateAsc(LocalDate startDate, LocalDate endDate);
}
