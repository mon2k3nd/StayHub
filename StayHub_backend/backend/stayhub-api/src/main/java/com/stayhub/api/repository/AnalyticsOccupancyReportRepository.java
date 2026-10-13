package com.stayhub.api.repository;

import com.stayhub.api.entity.AnalyticsOccupancyReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface AnalyticsOccupancyReportRepository extends JpaRepository<AnalyticsOccupancyReport, Long> {
    
    Optional<AnalyticsOccupancyReport> findByReportDate(LocalDate reportDate);
    
    List<AnalyticsOccupancyReport> findByReportDateBetweenOrderByReportDateAsc(LocalDate startDate, LocalDate endDate);
}
