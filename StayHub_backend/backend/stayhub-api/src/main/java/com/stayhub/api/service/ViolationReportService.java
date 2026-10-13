package com.stayhub.api.service;

import com.stayhub.api.entity.ViolationReport;

import java.util.List;

public interface ViolationReportService {
    List<ViolationReport> getViolationsByRoom(Long roomId);
    List<ViolationReport> getViolationsByContract(Long contractId);
    List<ViolationReport> getViolationsByTarget(String targetType, Long targetId);
    ViolationReport createViolation(ViolationReport violation);
    ViolationReport updateViolationStatus(Long id, String status);
    void deleteViolation(Long id);
}
