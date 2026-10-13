package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.StaffShift;
import com.stayhub.api.service.StaffShiftService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/staff-shifts")
@RequiredArgsConstructor
public class StaffShiftController {

    private final StaffShiftService staffShiftService;

    @PostMapping
    public ResponseEntity<ApiResponse<StaffShift>> createShift(@RequestBody StaffShift shift) {
        return ResponseEntity.ok(ApiResponse.<StaffShift>builder()
                .success(true)
                .message("Tạo ca làm việc thành công!")
                .data(staffShiftService.createShift(shift))
                .build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<StaffShift>> updateShift(@PathVariable Long id, @RequestBody StaffShift shift) {
        return ResponseEntity.ok(ApiResponse.<StaffShift>builder()
                .success(true)
                .message("Cập nhật ca làm việc thành công!")
                .data(staffShiftService.updateShift(id, shift))
                .build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteShift(@PathVariable Long id) {
        staffShiftService.deleteShift(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message("Xóa ca làm việc thành công!")
                .build());
    }

    @GetMapping("/branch/{branchId}")
    public ResponseEntity<ApiResponse<List<StaffShift>>> getShiftsByBranch(@PathVariable Long branchId) {
        return ResponseEntity.ok(ApiResponse.<List<StaffShift>>builder()
                .success(true)
                .data(staffShiftService.getShiftsByBranch(branchId))
                .build());
    }

    @GetMapping("/staff/{staffId}")
    public ResponseEntity<ApiResponse<List<StaffShift>>> getShiftsByStaff(@PathVariable Long staffId) {
        return ResponseEntity.ok(ApiResponse.<List<StaffShift>>builder()
                .success(true)
                .data(staffShiftService.getShiftsByStaff(staffId))
                .build());
    }
}
