package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.request.RentalRequestSubmitDto;
import com.stayhub.api.dto.response.RentalRequestResponseDto;
import com.stayhub.api.service.RentalRequestService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import com.stayhub.api.security.RentalSessionTokenProvider;
import com.stayhub.api.entity.Room;
import com.stayhub.api.repository.RoomRepository;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/rental-requests")
@RequiredArgsConstructor
public class V1RentalRequestController {

    private final RentalRequestService rentalRequestService;
    private final RentalSessionTokenProvider tokenProvider;
    private final RoomRepository roomRepository;

    // POST /v1/rental-requests/scan/{roomId} — Tạo JWT session token khi quét QR
    @PostMapping("/scan/{roomId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> scanRoom(@PathVariable Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy phòng"));
        
        if (room.getStatus() != com.stayhub.api.entity.RoomStatus.TRONG) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Phòng không còn trống");
        }

        String sessionToken = tokenProvider.generateToken(roomId);
        Map<String, Object> responseData = new HashMap<>();
        responseData.put("room", room);
        responseData.put("sessionToken", sessionToken);

        return ResponseEntity.ok(ApiResponse.ok(responseData));
    }

    // POST /v1/rental-requests — frontend rental_request_screen.dart & contract_remote_data_source.dart
    @PostMapping
    public ResponseEntity<ApiResponse<RentalRequestResponseDto>> createRequest(
            @RequestBody RentalRequestSubmitDto dto, org.springframework.security.core.Authentication auth) {
        
        if (auth != null && auth.getPrincipal() != null && !auth.getPrincipal().toString().equals("anonymousUser")) {
            dto.setTenantId(Long.parseLong(auth.getPrincipal().toString()));
        }
        
        RentalRequestResponseDto responseDto = rentalRequestService.createRequest(dto);
        return ResponseEntity.status(org.springframework.http.HttpStatus.CREATED).body(ApiResponse.ok(responseDto));
    }

    // POST /v1/rental-requests/submit — alias
    @PostMapping("/submit")
    public ResponseEntity<ApiResponse<RentalRequestResponseDto>> submitRequest(
            @RequestBody RentalRequestSubmitDto dto, org.springframework.security.core.Authentication auth) {
        
        if (auth != null && auth.getPrincipal() != null && !auth.getPrincipal().toString().equals("anonymousUser")) {
            dto.setTenantId(Long.parseLong(auth.getPrincipal().toString()));
        }
        
        RentalRequestResponseDto responseDto = rentalRequestService.createRequest(dto);
        return ResponseEntity.status(org.springframework.http.HttpStatus.CREATED).body(ApiResponse.ok(responseDto));
    }

    // GET /v1/rental-requests — rental_requests_list_screen.dart (owner xem danh sách)
    @GetMapping
    public ResponseEntity<ApiResponse<List<RentalRequestResponseDto>>> getAllRequests(Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Không có quyền truy cập");
        }
        Long userId = (Long) auth.getPrincipal();
        List<RentalRequestResponseDto> list = rentalRequestService.getPendingRequestsByOwner(userId);
        return ResponseEntity.ok(ApiResponse.ok(list));
    }

    // GET /v1/rental-requests/owner/{ownerId}
    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<ApiResponse<List<RentalRequestResponseDto>>> getPendingRequests(
            @PathVariable Long ownerId,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!userId.equals(ownerId) && !isStaff) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền xem yêu cầu của chủ nhà khác");
        }
        
        List<RentalRequestResponseDto> pending = rentalRequestService.getPendingRequestsByOwner(ownerId);
        return ResponseEntity.ok(ApiResponse.ok(pending));
    }

    // GET /v1/rental-requests/tenant/{tenantId}/latest
    @GetMapping("/tenant/{tenantId}/latest")
    public ResponseEntity<ApiResponse<RentalRequestResponseDto>> getLatestRequestByTenant(
            @PathVariable Long tenantId,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null || !tenantId.equals(auth.getPrincipal())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Không có quyền truy cập");
        }
        RentalRequestResponseDto requestDto = rentalRequestService.getLatestRequestByTenant(tenantId);
        return ResponseEntity.ok(ApiResponse.ok(requestDto));
    }

    // POST /v1/rental-requests/{id}/pay-deposit
    @PostMapping("/{id}/pay-deposit")
    public ResponseEntity<ApiResponse<RentalRequestResponseDto>> payDeposit(@PathVariable Long id, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        com.stayhub.api.entity.RentalRequest req = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RentalRequestRepository.class).findById(id).orElse(null);
        if (req == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy yêu cầu");
        
        // MVP: Only tenant can simulate paying deposit, or Owner. 
        if (!req.getTenantId().equals(userId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_OWNER"))) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền thực hiện thanh toán này");
        }
        
        RentalRequestResponseDto responseDto = rentalRequestService.payDeposit(id);
        return ResponseEntity.ok(ApiResponse.ok(responseDto));
    }

    // GET /v1/rental-requests/stream/owner/{ownerId} — SSE real-time (Owner)
    @GetMapping("/stream/owner/{ownerId}")
    public SseEmitter streamEvents(@PathVariable Long ownerId, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null || !ownerId.equals(auth.getPrincipal())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền theo dõi luồng thông báo này");
        }
        return rentalRequestService.registerEmitter(ownerId);
    }

    // GET /v1/rental-requests/stream/{tenantId} — SSE real-time (Tenant xem trạng thái yêu cầu của mình)
    @GetMapping("/stream/{tenantId}")
    public SseEmitter streamTenantEvents(@PathVariable Long tenantId, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null || !tenantId.equals(auth.getPrincipal())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền theo dõi luồng thông báo này");
        }
        return rentalRequestService.registerEmitter(tenantId);
    }

    // POST /v1/rental-requests/{id}/respond — rental_requests_list_screen.dart
    @PostMapping("/{id}/respond")
    public ResponseEntity<ApiResponse<RentalRequestResponseDto>> respondRequest(
            @PathVariable Long id,
            @RequestBody Map<String, Object> body) {
        Long ownerId = (Long) org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        boolean approved = Boolean.TRUE.equals(body.get("approved"));
        Integer durationMonths = null;
        if (body.containsKey("durationMonths") && body.get("durationMonths") != null) {
            durationMonths = Integer.valueOf(body.get("durationMonths").toString());
        }
        String terms = body.containsKey("terms") ? body.get("terms").toString() : null;
        RentalRequestResponseDto responseDto = rentalRequestService.respondToRequest(ownerId, id, approved, durationMonths, terms);
        return ResponseEntity.ok(ApiResponse.ok(responseDto));
    }

    // PUT /v1/rental-requests/{id}/approve — rental_request_notifier.dart
    @PutMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<RentalRequestResponseDto>> approveRequest(
            @PathVariable Long id,
            @RequestBody(required = false) Map<String, Object> body) {
        Long ownerId = (Long) org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        Integer durationMonths = null;
        String terms = null;
        if (body != null) {
            if (body.containsKey("durationMonths") && body.get("durationMonths") != null) {
                durationMonths = Integer.valueOf(body.get("durationMonths").toString());
            }
            if (body.containsKey("terms") && body.get("terms") != null) {
                terms = body.get("terms").toString();
            }
        }
        RentalRequestResponseDto responseDto = rentalRequestService.respondToRequest(ownerId, id, true, durationMonths, terms);
        return ResponseEntity.ok(ApiResponse.ok(responseDto));
    }

    // PUT /v1/rental-requests/{id}/cancel — cancel a request
    @PutMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<Void>> cancelRequest(
            @PathVariable Long id, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Không có quyền truy cập");
        }
        Long userId = (Long) auth.getPrincipal();
        rentalRequestService.cancelRequest(id, userId);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true).message("Đã hủy yêu cầu thuê phòng").build());
    }
}
