package com.stayhub.api.controller;

import com.stayhub.api.dto.response.VoucherResponse;
import com.stayhub.api.entity.Room;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.service.VoucherManagementService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/vouchers/tenant")
@RequiredArgsConstructor
public class VoucherTenantController {

    private final VoucherManagementService voucherManagementService;
    private final RoomRepository roomRepository;

    @GetMapping("/room/{roomId}")
    public ResponseEntity<List<VoucherResponse>> getApplicableVouchersForRoom(@PathVariable Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Room not found"));
        
        List<VoucherResponse> vouchers = voucherManagementService.getActiveVouchersForRoom(roomId, room.getOwnerId());
        return ResponseEntity.ok(vouchers);
    }
}
