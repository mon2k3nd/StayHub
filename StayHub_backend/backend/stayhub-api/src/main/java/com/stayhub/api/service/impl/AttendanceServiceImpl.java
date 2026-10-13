package com.stayhub.api.service.impl;

import com.stayhub.api.dto.request.AttendanceRequestDto;
import com.stayhub.api.dto.response.AttendanceDto;
import com.stayhub.api.entity.AttendanceLog;
import com.stayhub.api.entity.Branch;
import com.stayhub.api.entity.User;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.AttendanceRepository;
import com.stayhub.api.repository.BranchRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.service.AttendanceService;
import com.stayhub.api.service.NotificationService;
import com.stayhub.api.entity.NotificationType;
import com.stayhub.api.entity.NotificationScope;
import org.springframework.web.server.ResponseStatusException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AttendanceServiceImpl implements AttendanceService {

    private static final double EARTH_RADIUS_KM = 6371.0;

    private final AttendanceRepository attendanceRepository;
    private final UserRepository userRepository;
    private final BranchRepository branchRepository;
    private final NotificationService notificationService;

    @Override
    public AttendanceDto checkIn(String userEmail, AttendanceRequestDto request) {
        User staff = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found"));

        if (attendanceRepository.findByStaffIdAndCheckOutTimeIsNull(staff.getId()).isPresent()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "You are already checked in");
        }

        Branch branch = null;
        double distance = 0.0;
        String status = "ON_TIME";

        if (request.getBranchId() != null) {
            branch = branchRepository.findById(request.getBranchId())
                    .orElse(null);
            
            if (branch != null && branch.getLatitude() != null && branch.getLongitude() != null && request.getLatitude() != null && request.getLongitude() != null) {
                distance = calculateHaversineDistance(request.getLatitude(), request.getLongitude(), branch.getLatitude(), branch.getLongitude()) * 1000;
                if (distance > 200) {
                    status = "INVALID_LOCATION";
                }
            } else if (branch != null && (branch.getLatitude() == null || branch.getLongitude() == null)) {
                status = "NO_BRANCH_LOCATION";
            } else if (request.getLatitude() == null || request.getLongitude() == null) {
                status = "NO_GPS_PROVIDED";
            }
        }

        AttendanceLog log = AttendanceLog.builder()
                .staff(staff)
                .branch(branch)
                .checkInTime(LocalDateTime.now())
                .checkInLocation(request.getLocation())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .distanceMeters(distance)
                .status(status)
                .checkInPhotoUrl(request.getPhotoBase64()) // For simplicity, saving base64/url directly
                .build();

        attendanceRepository.save(log);

        if (branch != null && branch.getOwnerId() != null) {
            String warningMsg = "INVALID_LOCATION".equals(status) ? " (Sai vị trí > 200m)" : "";
            notificationService.send(staff.getId(), branch.getOwnerId(), NotificationScope.INDIVIDUAL,
                    "Nhân viên Check-in",
                    "Nhân viên " + staff.getName() + " vừa check-in tại " + branch.getBranchName() + warningMsg,
                    NotificationType.GENERAL, log.getId(), false, null, null);
        }

        return mapToDto(log);
    }

    @Override
    public AttendanceDto checkOut(String userEmail, AttendanceRequestDto request) {
        User staff = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found"));

        AttendanceLog log = attendanceRepository.findByStaffIdAndCheckOutTimeIsNull(staff.getId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "No active check-in found"));

        log.setCheckOutTime(LocalDateTime.now());
        log.setCheckOutLocation(request.getLocation());
        if (request.getPhotoBase64() != null) {
            log.setCheckOutPhotoUrl(request.getPhotoBase64());
        }
        attendanceRepository.save(log);

        if (log.getBranch() != null && log.getBranch().getOwnerId() != null) {
            notificationService.send(staff.getId(), log.getBranch().getOwnerId(), NotificationScope.INDIVIDUAL,
                    "Nhân viên Check-out",
                    "Nhân viên " + staff.getName() + " vừa check-out khỏi " + log.getBranch().getBranchName(),
                    NotificationType.GENERAL, log.getId(), false, null, null);
        }

        return mapToDto(log);
    }

    @Override
    public AttendanceDto getCurrentStatus(String userEmail) {
        User staff = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found"));

        return attendanceRepository.findByStaffIdAndCheckOutTimeIsNull(staff.getId())
                .map(this::mapToDto)
                .orElse(null);
    }

    @Override
    public List<AttendanceDto> getMyLogs(String userEmail) {
        User staff = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new ResourceNotFoundException("Staff not found"));

        return attendanceRepository.findByStaffIdOrderByCheckInTimeDesc(staff.getId())
                .stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    private AttendanceDto mapToDto(AttendanceLog log) {
        return AttendanceDto.builder()
                .id(log.getId())
                .staffId(log.getStaff().getId())
                .branchId(log.getBranch() != null ? log.getBranch().getId() : null)
                .branchName(log.getBranch() != null ? log.getBranch().getBranchName() : null)
                .checkInTime(log.getCheckInTime())
                .checkOutTime(log.getCheckOutTime())
                .checkInLocation(log.getCheckInLocation())
                .checkOutLocation(log.getCheckOutLocation())
                .latitude(log.getLatitude())
                .longitude(log.getLongitude())
                .distanceMeters(log.getDistanceMeters())
                .status(log.getStatus())
                .checkInPhotoUrl(log.getCheckInPhotoUrl())
                .checkOutPhotoUrl(log.getCheckOutPhotoUrl())
                .build();
    }

    private double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        lat1 = Math.toRadians(lat1);
        lat2 = Math.toRadians(lat2);

        double a = Math.pow(Math.sin(dLat / 2), 2) +
                   Math.pow(Math.sin(dLon / 2), 2) *
                   Math.cos(lat1) *
                   Math.cos(lat2);
        
        double c = 2 * Math.asin(Math.sqrt(a));
        return EARTH_RADIUS_KM * c;
    }
}
