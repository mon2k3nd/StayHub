package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.RoomReport;
import com.stayhub.api.repository.RoomReportRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;
import java.time.LocalDateTime;

@RestController
@RequestMapping("/v1/rooms/reports")
@RequiredArgsConstructor
public class V1RoomReportController {

    private final RoomReportRepository repository;

    @PostMapping
    public ResponseEntity<ApiResponse<RoomReport>> submitReport(@RequestBody RoomReport report, Authentication auth) {
        report.setCreatedAt(LocalDateTime.now());
        if (auth != null && auth.getPrincipal() != null && !auth.getPrincipal().toString().equals("anonymousUser")) {
            report.setReporterId(Long.parseLong(auth.getPrincipal().toString()));
        }
        return ResponseEntity.ok(ApiResponse.ok(repository.save(report)));
    }
}
