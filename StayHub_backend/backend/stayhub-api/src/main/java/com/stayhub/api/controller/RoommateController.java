package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Roommate;
import com.stayhub.api.service.RoommateService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/roommates")
@RequiredArgsConstructor
public class RoommateController {

    private final RoommateService roommateService;

    @GetMapping("/contract/{contractId}")
    public ResponseEntity<ApiResponse<List<Roommate>>> getByContract(
            @PathVariable Long contractId,
            org.springframework.security.core.Authentication auth) {
        
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        com.stayhub.api.entity.Contract contract = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.ContractRepository.class).findById(contractId).orElse(null);
        if (contract != null) {
            com.stayhub.api.entity.Room room = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(contract.getRoomId()).orElse(null);
            if (room != null && !isStaff) {
                if (!contract.getTenantId().equals(userId) && !room.getOwnerId().equals(userId)) {
                    throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền xem thông tin khách cùng phòng của hợp đồng này");
                }
            }
        }
        
        return ResponseEntity.ok(ApiResponse.<List<Roommate>>builder()
                .success(true).message("Thành công!")
                .data(roommateService.getByContract(contractId)).build());
    }


    @GetMapping("/room/{roomId}")
    public ResponseEntity<ApiResponse<List<Roommate>>> getByRoom(
            @PathVariable Long roomId,
            org.springframework.security.core.Authentication auth) {
        
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        com.stayhub.api.entity.Room room = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(roomId).orElse(null);
        if (room != null && !isStaff) {
            if (!userId.equals(room.getCurrentTenantId()) && !userId.equals(room.getOwnerId())) {
                throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền xem thông tin khách phòng này");
            }
        }
        
        List<Roommate> roommates = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoommateRepository.class).findByRoomIdAndIsActiveTrue(roomId);
        return ResponseEntity.ok(ApiResponse.<List<Roommate>>builder()
                .success(true).message("Thành công!")
                .data(roommates).build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Roommate>> updateRoommate(
            @PathVariable Long id,
            @RequestBody java.util.Map<String, Object> updates,
            org.springframework.security.core.Authentication auth) {
        Roommate r = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoommateRepository.class).findById(id).orElse(null);
        if (r == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy");
        if (updates.containsKey("isEkycVerified")) {
            r.setIsEkycVerified((Boolean) updates.get("isEkycVerified"));
        }
        if (updates.containsKey("role")) {
            r.setRole((String) updates.get("role"));
        }
        com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoommateRepository.class).save(r);
        return ResponseEntity.ok(ApiResponse.<Roommate>builder().success(true).data(r).build());
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Roommate>> addRoommate(
            @RequestBody Roommate roommate,
            org.springframework.security.core.Authentication auth) {
        try {
            if (auth == null || auth.getPrincipal() == null) {
                throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
            }
            Long userId = (Long) auth.getPrincipal();
            boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
            
            com.stayhub.api.entity.Contract contract = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.ContractRepository.class).findById(roommate.getContractId()).orElse(null);
            if (contract == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.BAD_REQUEST, "Hợp đồng không tồn tại");
            
            com.stayhub.api.entity.Room room = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(contract.getRoomId()).orElse(null);
            if (room == null) throw new org.springframework.web.server.ResponseStatusException(HttpStatus.BAD_REQUEST, "Phòng không tồn tại");

            if (!isStaff) {
                 if (!contract.getTenantId().equals(userId) && !room.getOwnerId().equals(userId)) {
                     throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền thêm người vào phòng này");
                 }
            }

            return ResponseEntity.ok(ApiResponse.<Roommate>builder()
                    .success(true).message("Thêm bạn cùng phòng thành công!")
                    .data(roommateService.addRoommate(roommate)).build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Roommate>builder().success(false).message(e.getMessage()).build());
        }
    }

    @PostMapping("/{id}/checkout")
    public ResponseEntity<ApiResponse<Void>> checkout(
            @PathVariable Long id,
            org.springframework.security.core.Authentication auth) {
        try {
            if (auth == null || auth.getPrincipal() == null) {
                throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
            }
            Long userId = (Long) auth.getPrincipal();
            boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));

            Roommate roommate = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoommateRepository.class).findById(id).orElse(null);
            if (roommate != null) {
                com.stayhub.api.entity.Contract contract = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.ContractRepository.class).findById(roommate.getContractId()).orElse(null);
                if (contract != null) {
                    com.stayhub.api.entity.Room room = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(contract.getRoomId()).orElse(null);
                    if (room != null && !isStaff) {
                        if (!contract.getTenantId().equals(userId) && !room.getOwnerId().equals(userId)) {
                            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền xóa người ở cùng trong phòng này");
                        }
                    }
                }
            }

            roommateService.checkout(id);
            return ResponseEntity.ok(ApiResponse.<Void>builder()
                    .success(true).message("Đã xóa người ở cùng!").build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Void>builder().success(false).message(e.getMessage()).build());
        }
    }
}
