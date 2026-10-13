package com.stayhub.api.service;

import com.stayhub.api.entity.StaffShift;

import java.util.List;

public interface StaffShiftService {
    StaffShift createShift(StaffShift shift);
    StaffShift updateShift(Long id, StaffShift shift);
    void deleteShift(Long id);
    List<StaffShift> getShiftsByBranch(Long branchId);
    List<StaffShift> getShiftsByStaff(Long staffId);
}
