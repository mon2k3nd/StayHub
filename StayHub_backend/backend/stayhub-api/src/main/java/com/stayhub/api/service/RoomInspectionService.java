package com.stayhub.api.service;

import com.stayhub.api.dto.request.RoomInspectionRequest;
import com.stayhub.api.entity.RoomInspection;
import java.util.List;

public interface RoomInspectionService {
    RoomInspection createInspection(Long staffId, RoomInspectionRequest request);
    RoomInspection updateInspection(Long staffId, Long id, RoomInspectionRequest request);
    List<RoomInspection> getInspectionsByRoom(Long roomId);
    RoomInspection getInspectionById(Long id);
}
