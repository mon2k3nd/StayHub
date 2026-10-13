package com.stayhub.api.service;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.request.ComplaintRequest;
import com.stayhub.api.dto.request.ComplaintStatusUpdateRequest;
import com.stayhub.api.dto.response.ComplaintResponse;

import java.util.List;

public interface ComplaintService {
    ApiResponse<ComplaintResponse> createComplaint(Long tenantId, ComplaintRequest request);
    ApiResponse<List<ComplaintResponse>> getComplaintsByBranch(Long branchId, String status);
    ApiResponse<List<ComplaintResponse>> getComplaintsByTenant(Long tenantId);
    ApiResponse<ComplaintResponse> updateComplaintStatus(Long complaintId, Long adminId, ComplaintStatusUpdateRequest request);
}
