package com.stayhub.api.controller;

import com.stayhub.api.entity.BranchMeter;
import com.stayhub.api.service.BranchMeterService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/v1/branch-meters")
@RequiredArgsConstructor
public class BranchMeterController {

    private final BranchMeterService branchMeterService;

    @PostMapping("/{branchId}")
    public ResponseEntity<BranchMeter> saveMasterMeter(
            @PathVariable Long branchId,
            @RequestParam int month,
            @RequestParam int year,
            @RequestParam(required = false) Double electricCurrent,
            @RequestParam(required = false) Double waterCurrent) {
        return ResponseEntity.ok(branchMeterService.saveMasterMeter(branchId, month, year, electricCurrent, waterCurrent));
    }

    @GetMapping("/{branchId}/leakage")
    public ResponseEntity<Map<String, Object>> getLeakageReport(
            @PathVariable Long branchId,
            @RequestParam int month,
            @RequestParam int year) {
        return ResponseEntity.ok(branchMeterService.getUtilityLeakageReport(branchId, month, year));
    }
}
