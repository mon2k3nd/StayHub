package com.stayhub.api.service.impl;

import com.stayhub.api.dto.request.InspectionItemRequest;
import com.stayhub.api.dto.request.RoomInspectionRequest;
import com.stayhub.api.entity.InspectionItem;
import com.stayhub.api.entity.RoomInspection;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.InspectionItemRepository;
import com.stayhub.api.repository.RoomInspectionRepository;
import com.stayhub.api.service.RoomInspectionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoomInspectionServiceImpl implements RoomInspectionService {

    private final RoomInspectionRepository inspectionRepository;
    private final InspectionItemRepository itemRepository;

    @Override
    @Transactional
    public RoomInspection createInspection(Long staffId, RoomInspectionRequest request) {
        RoomInspection inspection = RoomInspection.builder()
                .roomId(request.getRoomId())
                .tenantId(request.getTenantId())
                .staffId(staffId)
                .type(request.getType())
                .status("COMPLETED")
                .notes(request.getNotes())
                .tenantSignatureUrl(request.getTenantSignatureUrl())
                .staffSignatureUrl(request.getStaffSignatureUrl())
                .build();

        RoomInspection savedInspection = inspectionRepository.save(inspection);

        if (request.getItems() != null && !request.getItems().isEmpty()) {
            List<InspectionItem> items = request.getItems().stream().map(req -> 
                InspectionItem.builder()
                    .inspectionId(savedInspection.getId())
                    .itemName(req.getItemName())
                    .isGood(req.getIsGood())
                    .notes(req.getNotes())
                    .photoUrl(req.getPhotoUrl())
                    .build()
            ).collect(Collectors.toList());
            itemRepository.saveAll(items);
            savedInspection.setItems(items);
        }

        return savedInspection;
    }

    @Override
    @Transactional
    public RoomInspection updateInspection(Long staffId, Long id, RoomInspectionRequest request) {
        RoomInspection inspection = inspectionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy biên bản"));
        
        inspection.setNotes(request.getNotes());
        inspection.setStatus("COMPLETED");
        if (request.getTenantSignatureUrl() != null) {
            inspection.setTenantSignatureUrl(request.getTenantSignatureUrl());
        }
        if (request.getStaffSignatureUrl() != null) {
            inspection.setStaffSignatureUrl(request.getStaffSignatureUrl());
        }

        RoomInspection savedInspection = inspectionRepository.save(inspection);

        if (request.getItems() != null) {
            // Xóa cũ thêm mới cho đơn giản
            List<InspectionItem> oldItems = itemRepository.findByInspectionId(id);
            itemRepository.deleteAll(oldItems);

            List<InspectionItem> items = request.getItems().stream().map(req -> 
                InspectionItem.builder()
                    .inspectionId(savedInspection.getId())
                    .itemName(req.getItemName())
                    .isGood(req.getIsGood())
                    .notes(req.getNotes())
                    .photoUrl(req.getPhotoUrl())
                    .build()
            ).collect(Collectors.toList());
            itemRepository.saveAll(items);
            savedInspection.setItems(items);
        }

        return savedInspection;
    }

    @Override
    public List<RoomInspection> getInspectionsByRoom(Long roomId) {
        List<RoomInspection> inspections = inspectionRepository.findByRoomId(roomId);
        for (RoomInspection ins : inspections) {
            ins.setItems(itemRepository.findByInspectionId(ins.getId()));
        }
        return inspections;
    }

    @Override
    public RoomInspection getInspectionById(Long id) {
        RoomInspection inspection = inspectionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy biên bản"));
        inspection.setItems(itemRepository.findByInspectionId(id));
        return inspection;
    }
}
