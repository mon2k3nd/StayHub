package com.stayhub.api.controller;

import com.stayhub.api.dto.request.AttendanceRequestDto;
import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/v1/attendance")
@RequiredArgsConstructor
public class V1AttendanceController {

    private final AttendanceService attendanceService;

    @PostMapping("/check-in")
    public ResponseEntity<?> checkIn(Authentication authentication, @RequestBody AttendanceRequestDto request) {
        return ResponseEntity.ok(ApiResponse.ok(
                attendanceService.checkIn(authentication.getName(), request)
        ));
    }

    @PostMapping("/check-out")
    public ResponseEntity<?> checkOut(Authentication authentication, @RequestBody AttendanceRequestDto request) {
        return ResponseEntity.ok(ApiResponse.ok(
                attendanceService.checkOut(authentication.getName(), request)
        ));
    }

    @GetMapping("/status")
    public ResponseEntity<?> getCurrentStatus(Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.ok(
                attendanceService.getCurrentStatus(authentication.getName())
        ));
    }

    @GetMapping("/logs")
    public ResponseEntity<?> getMyLogs(Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.ok(
                attendanceService.getMyLogs(authentication.getName())
        ));
    }
}
