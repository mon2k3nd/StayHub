package com.stayhub.api.service.impl;

import com.stayhub.api.entity.RoomAsset;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.RoomAssetRepository;
import com.stayhub.api.service.RoomAssetService;
import com.stayhub.api.service.AuditLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RoomAssetServiceImpl implements RoomAssetService {

    private final RoomAssetRepository roomAssetRepository;
    private final AuditLogService auditLogService;

    @Override
    public List<RoomAsset> getByRoom(Long roomId) {
        return roomAssetRepository.findByRoomId(roomId);
    }

    @Override
    public RoomAsset create(RoomAsset asset) {
        asset.setCreatedAt(LocalDateTime.now());
        asset.setUpdatedAt(LocalDateTime.now());
        RoomAsset saved = roomAssetRepository.save(asset);
        auditLogService.logAction(
                "ROOM_ASSET", saved.getId(), "CREATE",
                null, "System", // Or extract from SecurityContext if available
                String.format("Thêm tài sản mới: %s (x%d) cho phòng ID %d", saved.getAssetName(), saved.getQuantity(), saved.getRoomId())
        );
        return saved;
    }

    @Override
    public RoomAsset update(Long id, RoomAsset updated) {
        RoomAsset existing = roomAssetRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài sản ID: " + id));
        
        String oldChanges = String.format("Cũ: %s (x%d) - %s", existing.getAssetName(), existing.getQuantity(), existing.getAssetStatus());
        
        existing.setAssetName(updated.getAssetName());
        existing.setQuantity(updated.getQuantity());
        existing.setConditionNote(updated.getConditionNote());
        existing.setAssetStatus(updated.getAssetStatus());
        existing.setValue(updated.getValue());
        existing.setUpdatedAt(LocalDateTime.now());
        
        RoomAsset saved = roomAssetRepository.save(existing);
        
        auditLogService.logAction(
                "ROOM_ASSET", id, "UPDATE",
                null, "System",
                oldChanges + " -> Mới: " + saved.getAssetName() + " (x" + saved.getQuantity() + ") - " + saved.getAssetStatus()
        );
        return saved;
    }

    @Override
    public void delete(Long id) {
        RoomAsset existing = roomAssetRepository.findById(id).orElse(null);
        if (existing != null) {
            auditLogService.logAction(
                    "ROOM_ASSET", id, "DELETE",
                    null, "System",
                    String.format("Xóa tài sản: %s (x%d) của phòng ID %d", existing.getAssetName(), existing.getQuantity(), existing.getRoomId())
            );
            roomAssetRepository.deleteById(id);
        }
    }
}
