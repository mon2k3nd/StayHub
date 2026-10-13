package com.stayhub.api.controller;

import com.stayhub.api.entity.SmartDevice;
import com.stayhub.api.repository.SmartDeviceRepository;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/smart-devices")
@RequiredArgsConstructor
public class V1SmartDeviceController {

    private final SmartDeviceRepository smartDeviceRepository;

    @GetMapping("/room/{roomId}")
    public ResponseEntity<List<SmartDevice>> getDevicesByRoom(@PathVariable Long roomId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        com.stayhub.api.entity.Room room = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(roomId).orElse(null);
        if (room == null || (!userId.equals(room.getCurrentTenantId()) && !userId.equals(room.getOwnerId()))) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền xem thiết bị của phòng này");
        }
        List<SmartDevice> devices = smartDeviceRepository.findByRoomId(roomId);
        return ResponseEntity.ok(devices);
    }

    @PutMapping("/{id}/toggle")
    @Transactional
    public ResponseEntity<SmartDevice> toggleDevice(
            @PathVariable Long id, 
            @RequestBody Map<String, String> request,
            org.springframework.security.core.Authentication auth) {
            
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();

        SmartDevice device = smartDeviceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Device not found"));
                
        com.stayhub.api.entity.Room room = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(device.getRoomId()).orElse(null);
        if (room == null || (!userId.equals(room.getCurrentTenantId()) && !userId.equals(room.getOwnerId()))) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền điều khiển thiết bị này");
        }
        
        String newStatus = request.get("status");
        if (newStatus != null) {
            device.setStatus(newStatus);
            device.setLastPingAt(LocalDateTime.now());
            device = smartDeviceRepository.save(device);
        }
        return ResponseEntity.ok(device);
    }

    @PutMapping("/{id}/settings")
    @Transactional
    public ResponseEntity<SmartDevice> updateDeviceSettings(
            @PathVariable Long id, 
            @RequestBody Map<String, Object> request,
            org.springframework.security.core.Authentication auth) {
            
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        
        SmartDevice device = smartDeviceRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Device not found"));

        com.stayhub.api.entity.Room room = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(device.getRoomId()).orElse(null);
        if (room == null || (!userId.equals(room.getCurrentTenantId()) && !userId.equals(room.getOwnerId()))) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền cài đặt thiết bị này");
        }

        try {
            // Using a simple JSON serialization for settings map
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            String settingsJson = mapper.writeValueAsString(request);
            device.setSettings(settingsJson);
            device.setLastPingAt(LocalDateTime.now());
            device = smartDeviceRepository.save(device);
        } catch (Exception e) {
            throw new RuntimeException("Failed to update settings", e);
        }

        return ResponseEntity.ok(device);
    }
    
    // Seed devices for testing
    @PostMapping("/room/{roomId}/seed")
    @Transactional
    public ResponseEntity<List<SmartDevice>> seedDevices(@PathVariable Long roomId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        com.stayhub.api.entity.Room room = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(roomId).orElse(null);
        if (room == null || (!userId.equals(room.getCurrentTenantId()) && !userId.equals(room.getOwnerId()))) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền tạo thiết bị cho phòng này");
        }
        if (!smartDeviceRepository.findByRoomId(roomId).isEmpty()) {
            return ResponseEntity.badRequest().build();
        }
        
        List<SmartDevice> defaultDevices = List.of(
            SmartDevice.builder().roomId(roomId).name("Đèn trần").deviceType("LIGHT").status("OFF").build(),
            SmartDevice.builder().roomId(roomId).name("Điều hòa").deviceType("AC").status("OFF").settings("{\"temp\": 24}").build(),
            SmartDevice.builder().roomId(roomId).name("Rèm ban công").deviceType("CURTAIN").status("CLOSED").build(),
            SmartDevice.builder().roomId(roomId).name("Khóa cửa chính").deviceType("LOCK").status("LOCKED").build()
        );
        
        List<SmartDevice> saved = smartDeviceRepository.saveAll(defaultDevices);
        return ResponseEntity.ok(saved);
    }
}
