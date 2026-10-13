package com.stayhub.api.service.impl;

import com.stayhub.api.entity.ViolationReport;
import com.stayhub.api.repository.ViolationReportRepository;
import com.stayhub.api.service.ViolationReportService;
import com.stayhub.api.service.AuditLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ViolationReportServiceImpl implements ViolationReportService {

    private final ViolationReportRepository violationReportRepository;
    private final AuditLogService auditLogService;

    @Override
    public List<ViolationReport> getViolationsByRoom(Long roomId) {
        return violationReportRepository.findByRoomId(roomId);
    }

    @Override
    public List<ViolationReport> getViolationsByContract(Long contractId) {
        return violationReportRepository.findByContractId(contractId);
    }

    @Override
    public List<ViolationReport> getViolationsByTarget(String targetType, Long targetId) {
        return violationReportRepository.findByTargetTypeAndTargetId(targetType, targetId);
    }

    @Override
    @Transactional
    public ViolationReport createViolation(ViolationReport violation) {
        ViolationReport saved = violationReportRepository.save(violation);
        auditLogService.logAction(
                "VIOLATION", saved.getId(), "CREATE",
                null, "System", // Or extract from context
                String.format("Tạo biên bản vi phạm %s cho %s ID %d. Phạt: %.0f", 
                    saved.getViolationType(), saved.getTargetType(), saved.getTargetId(), 
                    saved.getPenaltyAmount() != null ? saved.getPenaltyAmount() : 0.0)
        );
        return saved;
    }

    @Override
    @Transactional
    public ViolationReport updateViolationStatus(Long id, String status) {
        ViolationReport existing = violationReportRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Violation not found"));
        
        String oldStatus = existing.getStatus();
        existing.setStatus(status);
        ViolationReport saved = violationReportRepository.save(existing);
        
        auditLogService.logAction(
                "VIOLATION", id, "UPDATE_STATUS",
                null, "System",
                "Chuyển trạng thái: " + oldStatus + " -> " + status
        );
        return saved;
    }

    @Override
    @Transactional
    public void deleteViolation(Long id) {
        ViolationReport existing = violationReportRepository.findById(id).orElse(null);
        if (existing != null) {
            auditLogService.logAction(
                    "VIOLATION", id, "DELETE",
                    null, "System",
                    String.format("Xóa biên bản vi phạm %s của %s ID %d", 
                        existing.getViolationType(), existing.getTargetType(), existing.getTargetId())
            );
            violationReportRepository.deleteById(id);
        }
    }
}
