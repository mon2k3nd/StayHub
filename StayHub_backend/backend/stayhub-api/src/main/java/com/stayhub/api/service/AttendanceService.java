package com.stayhub.api.service;

import com.stayhub.api.dto.request.AttendanceRequestDto;
import com.stayhub.api.dto.response.AttendanceDto;

import java.util.List;

public interface AttendanceService {
    AttendanceDto checkIn(String userEmail, AttendanceRequestDto request);
    AttendanceDto checkOut(String userEmail, AttendanceRequestDto request);
    AttendanceDto getCurrentStatus(String userEmail);
    List<AttendanceDto> getMyLogs(String userEmail);
}
