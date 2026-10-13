package com.stayhub.api.service;

import com.stayhub.api.entity.Maintenance;
import org.springframework.web.multipart.MultipartFile;

public interface V1TicketService {
    java.util.List<Maintenance> getTicketsByTenant(Long tenantId);
    java.util.List<Maintenance> getTicketsByOwner(Long ownerId);
    java.util.List<Maintenance> getTicketsByStaff(Long staffId);
    Maintenance getTicketById(Long id);
    Maintenance createTicket(Long tenantId, Long roomId, String category, String description, String severity, String tenantDesire, MultipartFile image);
    Maintenance createTicketWithPool(Long tenantId, Long roomId, Long poolId, String category, String description, String severity, String tenantDesire, MultipartFile image);
    Maintenance createTicketWithFacility(Long tenantId, Long roomId, Long facilityId, String category, String description, String severity, String tenantDesire, MultipartFile image);
    Maintenance assignTicket(Long ownerId, Long ticketId, Long assignedStaffId);
    Maintenance completeTicket(Long staffId, Long ticketId, Double materialCost, Boolean isSuccessful, String repairDetails, MultipartFile image);
    Maintenance ownerCompleteTicket(Long ownerId, Long ticketId, Double materialCost, Boolean isSuccessful, String repairDetails, MultipartFile image);
    void approveTicket(Long ownerId, Long ticketId, Double staffBonus);
    void cancelTicket(Long ownerId, Long ticketId, String reason);
    void rejectTicket(Long ownerId, Long ticketId, String reason);
    Maintenance updateTicketStatus(Long staffId, Long ticketId, String status);
}
