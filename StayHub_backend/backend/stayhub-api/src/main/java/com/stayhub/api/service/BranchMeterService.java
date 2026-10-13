package com.stayhub.api.service;

import com.stayhub.api.entity.BranchMeter;
import java.util.Map;

public interface BranchMeterService {
    BranchMeter saveMasterMeter(Long branchId, int month, int year, Double elec, Double water);
    BranchMeter getMasterMeter(Long branchId, int month, int year);
    
    // So sánh lượng tiêu thụ tổng tòa nhà vs tổng các phòng
    Map<String, Object> getUtilityLeakageReport(Long branchId, int month, int year);
}
