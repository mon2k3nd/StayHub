package com.stayhub.api.controller;

import com.stayhub.api.dto.request.ToggleLockRequest;
import com.stayhub.api.dto.response.DeviceStatusResponse;
import com.stayhub.api.service.IoTDeviceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/iot")
@RequiredArgsConstructor
@CrossOrigin("*") // Or follow existing CORS policy
public class IoTDeviceController {

    private final IoTDeviceService iotDeviceService;

    @GetMapping("/room/{roomId}")
    public ResponseEntity<List<DeviceStatusResponse>> getRoomDevices(@PathVariable Long roomId) {
        return ResponseEntity.ok(iotDeviceService.getDevicesByRoom(roomId));
    }

    @PostMapping("/smart-lock/toggle")
    public ResponseEntity<DeviceStatusResponse> toggleSmartLock(@RequestBody ToggleLockRequest request) {
        return ResponseEntity.ok(iotDeviceService.toggleSmartLock(request));
    }
}
