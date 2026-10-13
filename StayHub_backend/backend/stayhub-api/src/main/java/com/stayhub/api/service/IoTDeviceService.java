package com.stayhub.api.service;

import com.stayhub.api.dto.request.ToggleLockRequest;
import com.stayhub.api.dto.response.DeviceStatusResponse;
import com.stayhub.api.entity.RoomDevice;
import com.stayhub.api.repository.RoomDeviceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class IoTDeviceService {

    private final RoomDeviceRepository roomDeviceRepository;

    @Transactional(readOnly = true)
    public List<DeviceStatusResponse> getDevicesByRoom(Long roomId) {
        List<RoomDevice> devices = roomDeviceRepository.findAll() // We'll filter via stream for simplicity if custom query doesn't exist yet
                .stream()
                .filter(d -> d.getRoomId().equals(roomId))
                .collect(Collectors.toList());

        return devices.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    @Transactional
    public DeviceStatusResponse toggleSmartLock(ToggleLockRequest request) {
        RoomDevice device = roomDeviceRepository.findById(request.getDeviceId())
                .orElseThrow(() -> new RuntimeException("Device not found"));

        if (device.getDeviceType() != 3) {
            throw new RuntimeException("Device is not a smart lock");
        }

        // TODO: In a real world scenario, call 3rd party API (e.g. Tuya/TTLock) to unlock/lock
        log.info("Sending command to Smart Lock ID {}: {}", device.getId(), request.getIsLocked() ? "LOCK" : "UNLOCK");
        
        // Simulating the IoT action: 
        // 1.0 is locked, 0.0 is unlocked for the sake of mapping double value to boolean
        device.setLastRecordedValue(request.getIsLocked() ? 1.0 : 0.0);
        device.setLastSyncTime(LocalDateTime.now());

        RoomDevice updated = roomDeviceRepository.save(device);
        return mapToResponse(updated);
    }

    private DeviceStatusResponse mapToResponse(RoomDevice device) {
        boolean isLocked = device.getLastRecordedValue() != null && device.getLastRecordedValue() > 0;
        return DeviceStatusResponse.builder()
                .deviceId(device.getId())
                .roomId(device.getRoomId())
                .deviceType(device.getDeviceType())
                .isLocked(isLocked)
                .lastRecordedValue(device.getLastRecordedValue())
                .lastSyncTime(device.getLastSyncTime())
                .statusMessage(device.getDeviceType() == 3 ? (isLocked ? "LOCKED" : "UNLOCKED") : "ONLINE")
                .build();
    }
}
