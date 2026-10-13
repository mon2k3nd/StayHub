package com.stayhub.api.service.impl;

import com.stayhub.api.entity.StaffShift;
import com.stayhub.api.repository.StaffShiftRepository;
import com.stayhub.api.service.StaffShiftService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class StaffShiftServiceImpl implements StaffShiftService {

    private final StaffShiftRepository staffShiftRepository;

    @Override
    public StaffShift createShift(StaffShift shift) {
        if (shift.getStatus() == null) {
            shift.setStatus(StaffShift.ShiftStatus.SCHEDULED);
        }
        return staffShiftRepository.save(shift);
    }

    @Override
    public StaffShift updateShift(Long id, StaffShift shiftDetails) {
        StaffShift existingShift = staffShiftRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Shift not found"));
        
        existingShift.setTitle(shiftDetails.getTitle());
        existingShift.setStartTime(shiftDetails.getStartTime());
        existingShift.setEndTime(shiftDetails.getEndTime());
        existingShift.setStaffId(shiftDetails.getStaffId());
        
        if (shiftDetails.getStatus() != null) {
            existingShift.setStatus(shiftDetails.getStatus());
        }

        return staffShiftRepository.save(existingShift);
    }

    @Override
    public void deleteShift(Long id) {
        staffShiftRepository.deleteById(id);
    }

    @Override
    public List<StaffShift> getShiftsByBranch(Long branchId) {
        return staffShiftRepository.findByBranchIdOrderByStartTimeDesc(branchId);
    }

    @Override
    public List<StaffShift> getShiftsByStaff(Long staffId) {
        return staffShiftRepository.findByStaffIdOrderByStartTimeDesc(staffId);
    }
}
