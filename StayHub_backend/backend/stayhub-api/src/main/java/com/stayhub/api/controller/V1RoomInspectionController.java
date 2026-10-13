package com.stayhub.api.controller;

import com.stayhub.api.dto.request.RoomInspectionRequest;
import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.RoomInspection;
import com.stayhub.api.service.RoomInspectionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/room-inspections")
@RequiredArgsConstructor
public class V1RoomInspectionController {

    private final RoomInspectionService inspectionService;

    @PostMapping
    public ResponseEntity<ApiResponse<RoomInspection>> create(
            @RequestBody RoomInspectionRequest request,
            Authentication auth) {
        Long staffId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ApiResponse.ok(inspectionService.createInspection(staffId, request)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<RoomInspection>> update(
            @PathVariable Long id,
            @RequestBody RoomInspectionRequest request,
            Authentication auth) {
        Long staffId = (Long) auth.getPrincipal();
        return ResponseEntity.ok(ApiResponse.ok(inspectionService.updateInspection(staffId, id, request)));
    }

    @GetMapping("/room/{roomId}")
    public ResponseEntity<ApiResponse<List<RoomInspection>>> getByRoom(@PathVariable Long roomId) {
        return ResponseEntity.ok(ApiResponse.ok(inspectionService.getInspectionsByRoom(roomId)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RoomInspection>> getById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(inspectionService.getInspectionById(id)));
    }
}
