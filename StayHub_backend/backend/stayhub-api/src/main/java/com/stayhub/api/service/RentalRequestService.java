package com.stayhub.api.service;

import com.stayhub.api.dto.request.RentalRequestSubmitDto;
import com.stayhub.api.dto.response.RentalRequestResponseDto;
import com.stayhub.api.entity.Branch;
import com.stayhub.api.entity.RentalRequest;
import com.stayhub.api.entity.Room;
import com.stayhub.api.entity.User;
import com.stayhub.api.entity.RoomStatus;
import com.stayhub.api.entity.RequestStatus;
import com.stayhub.api.repository.BranchRepository;
import com.stayhub.api.repository.RentalRequestRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.TenantProfileRepository;
import com.stayhub.api.entity.TenantProfile;
import com.stayhub.api.entity.KycStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import org.springframework.transaction.annotation.Transactional;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.stayhub.api.security.RentalSessionTokenProvider;
import org.springframework.jdbc.core.JdbcTemplate;
import jakarta.annotation.PostConstruct;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
public class RentalRequestService {

    private final RentalRequestRepository rentalRequestRepository;
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;
    private final BranchRepository branchRepository;
    private final NotificationService notificationService;
    private final RentalSessionTokenProvider tokenProvider;
    private final ObjectMapper objectMapper;
    private final ContractRepository contractRepository;
    private final TenantProfileRepository tenantProfileRepository;
    private final JdbcTemplate jdbcTemplate;
    private final PushNotificationService pushNotificationService;

    // ownerId -> list of emitters
    private final Map<Long, List<SseEmitter>> emitters = new ConcurrentHashMap<>();

    @Autowired
    public RentalRequestService(RentalRequestRepository rentalRequestRepository, 
                                RoomRepository roomRepository,
                                UserRepository userRepository,
                                BranchRepository branchRepository,
                                NotificationService notificationService,
                                RentalSessionTokenProvider tokenProvider,
                                ObjectMapper objectMapper,
                                ContractRepository contractRepository,
                                TenantProfileRepository tenantProfileRepository,
                                JdbcTemplate jdbcTemplate,
                                PushNotificationService pushNotificationService) {
        this.rentalRequestRepository = rentalRequestRepository;
        this.roomRepository = roomRepository;
        this.userRepository = userRepository;
        this.branchRepository = branchRepository;
        this.notificationService = notificationService;
        this.tokenProvider = tokenProvider;
        this.objectMapper = objectMapper;
        this.contractRepository = contractRepository;
        this.tenantProfileRepository = tenantProfileRepository;
        this.jdbcTemplate = jdbcTemplate;
        this.pushNotificationService = pushNotificationService;
    }

    @PostConstruct
    public void dropOldConstraints() {
        try {
            jdbcTemplate.execute("ALTER TABLE rental_requests DROP CONSTRAINT IF EXISTS rental_requests_status_check");
            jdbcTemplate.execute("ALTER TABLE rooms DROP CONSTRAINT IF EXISTS rooms_status_check");
            jdbcTemplate.execute("ALTER TABLE contracts DROP CONSTRAINT IF EXISTS contracts_status_check");
        } catch (Exception e) {
            System.err.println("Could not drop constraint: " + e.getMessage());
        }
    }

    // Create a new rental request
    public RentalRequestResponseDto createRequest(RentalRequestSubmitDto dto) {
        Room room = roomRepository.findById(dto.getRoomId())
                .orElseThrow(() -> new IllegalArgumentException("Room not found"));
                
        // Verify room is available (TRONG or CHO_DUYET)
        if (room.getStatus() != RoomStatus.TRONG && room.getStatus() != RoomStatus.CHO_DUYET) {
            throw new IllegalArgumentException("Phòng không còn trống, không thể gửi yêu cầu thuê");
        }
        
        // Validate Session Token only if provided (for backwards compatibility with OTP flow and direct QR scan)
        if (dto.getSessionToken() != null && !dto.getSessionToken().trim().isEmpty()) {
            if (!tokenProvider.validateToken(dto.getSessionToken(), dto.getRoomId())) {
                throw new IllegalArgumentException("Mã truy cập đã hết hạn hoặc không hợp lệ. Vui lòng quét lại mã QR.");
            }
        }

        // Enforce eKYC before requesting
        TenantProfile profile = tenantProfileRepository.findByUserId(dto.getTenantId()).orElse(null);
        if (profile == null || profile.getKycStatus() != KycStatus.APPROVED) {
            throw new IllegalArgumentException("Vui lòng hoàn tất xác thực định danh (eKYC) để tiếp tục gửi yêu cầu thuê phòng.");
        }
        
        // Convert FormData to Map
        Map<String, Object> formDataMap = objectMapper.convertValue(dto.getFormData(), new com.fasterxml.jackson.core.type.TypeReference<Map<String, Object>>() {});
        
        // Create request
        RentalRequest request = RentalRequest.builder()
                .roomId(dto.getRoomId())
                .tenantId(dto.getTenantId())
                .branchId(dto.getBranchId())
                .moveInDate(dto.getMoveInDate())
                .note(dto.getNote())
                .status(RequestStatus.PENDING)
                .submittedAt(LocalDateTime.now())
                .formData(formDataMap)
                .build();
        rentalRequestRepository.save(request);
        
        // DO NOT lock the room here (V.2 Architecture)
        // room.setStatus(RoomStatus.CHO_DUYET); 
        
        RentalRequestResponseDto responseDto = mapToResponseDto(request);
        // Notify owner via SSE
        notifyOwner(room.getOwnerId(), responseDto);
        // Prepare metadata payload for notification UI
        String metadataStr = "{\"endpoint\": \"/v1/rental-requests/" + request.getId() + "/respond\", \"method\": \"POST\", \"payload\": {"
                + "\"roomName\": \"" + room.getRoomName() + "\", "
                + "\"customerName\": \"" + responseDto.getTenantName() + "\", "
                + "\"phoneNumber\": \"" + (responseDto.getPhone() != null ? responseDto.getPhone() : "") + "\", "
                + "\"startDate\": \"" + (request.getMoveInDate() != null ? request.getMoveInDate().toString() : "") + "\", "
                + "\"duration\": \"\", "
                + "\"price\": \"" + room.getPrice() + "\", "
                + "\"deposit\": \"" + room.getDeposit() + "\", "
                + "\"note\": \"" + (request.getNote() != null ? request.getNote().replace("\"", "\\\"").replace("\n", "\\n") : "") + "\""
                + "}}";

        // Save notification to database
        notificationService.send(
                request.getTenantId(),
                room.getOwnerId(),
                com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                "Yêu cầu thuê phòng mới",
                "Có một yêu cầu thuê phòng mới cho phòng " + room.getRoomName() + " từ " + responseDto.getTenantName(),
                com.stayhub.api.entity.NotificationType.ROOM_RESERVED,
                request.getId(),
                true,
                com.stayhub.api.entity.NotificationActionStatus.PENDING,
                metadataStr
        );

        return responseDto;
    }

    @Transactional
    public RentalRequestResponseDto respondToRequest(Long ownerId, Long requestId, boolean approved, Integer durationMonths, String terms) {
        RentalRequest request = rentalRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Request not found"));
        
        Room room = roomRepository.findByIdWithLock(request.getRoomId())
                .orElseThrow(() -> new IllegalArgumentException("Room not found"));
        
        if (!room.getOwnerId().equals(ownerId)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Không có quyền duyệt yêu cầu này");
        }
        
        if (approved) {
            // Pessimistic logic - verify room is still TRONG
            if (room.getStatus() != RoomStatus.TRONG) {
                throw new IllegalStateException("Phòng đã được duyệt cho một yêu cầu khác");
            }
            request.setStatus(RequestStatus.APPROVED_WAITING_HANDOVER);
            room.setStatus(RoomStatus.NGHIEM_THU);
            
            // Bulk reject other pending requests for this room
            List<RentalRequest> otherPendingRequests = rentalRequestRepository.findAllByRoomIdInAndStatus(
                List.of(room.getId()), RequestStatus.PENDING
            );
            
            for (RentalRequest otherReq : otherPendingRequests) {
                if (!otherReq.getId().equals(request.getId())) {
                    otherReq.setStatus(RequestStatus.REJECTED);
                    rentalRequestRepository.save(otherReq);
                    
                    // Notify rejected tenants
                    notificationService.send(
                        room.getOwnerId(),
                        otherReq.getTenantId(),
                        com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                        "Yêu cầu thuê bị từ chối",
                        "Phòng " + room.getRoomName() + " đã có người thuê. Vui lòng chọn phòng khác.",
                        com.stayhub.api.entity.NotificationType.GENERAL,
                        otherReq.getId(), false, null, null
                    );
                }
            }

            User owner = userRepository.findById(room.getOwnerId()).orElse(new User());

            // Create Contract Pending
            int months = (durationMonths != null && durationMonths > 0) ? durationMonths : 6;
            String contractTerms = (terms != null && !terms.trim().isEmpty()) ? terms : (room.getDetailedInfo() != null ? room.getDetailedInfo().toString() : "");

            com.stayhub.api.entity.Contract contract = com.stayhub.api.entity.Contract.builder()
                .roomId(room.getId())
                .tenantId(request.getTenantId())
                .ownerId(room.getOwnerId())
                .startDate(java.time.LocalDate.now())
                .endDate(java.time.LocalDate.now().plusMonths(months))
                .monthlyRent(room.getPrice() != null ? room.getPrice() : 0.0)
                .depositAmount(room.getDeposit() != null ? room.getDeposit() : 0.0)
                .electricityPrice(room.getElectricityPrice() != null ? room.getElectricityPrice() : 0.0)
                .waterPrice(room.getWaterPrice() != null ? room.getWaterPrice() : 0.0)
                .serviceFee(room.getServiceFee() != null ? room.getServiceFee() : 0.0)
                .terms(contractTerms)
                .ownerSignature(owner.getOwnerProfile() != null ? owner.getOwnerProfile().getSignature() : null)
                .status(com.stayhub.api.entity.ContractStatus.PENDING)
                .build();
            contractRepository.save(contract);

            // Notify Tenant to sign
            notificationService.send(
                room.getOwnerId(),
                request.getTenantId(),
                com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                "Yêu cầu đã được duyệt!",
                "Chủ nhà đã duyệt yêu cầu thuê. Vui lòng tiến hành Ký Hợp Đồng & Chụp ảnh nghiệm thu ngay.",
                com.stayhub.api.entity.NotificationType.GENERAL,
                contract.getId(), false, null, null
            );
            
            // Emit SSE for Tenant to trigger UI navigation
            notifyOwner(request.getTenantId(), mapToResponseDto(request));
        } else {
            request.setStatus(RequestStatus.REJECTED);
        }
        
        rentalRequestRepository.save(request);
        roomRepository.save(room);
        
        RentalRequestResponseDto responseDto = mapToResponseDto(request);
        // Notify owner about approval
        notifyOwner(room.getOwnerId(), responseDto);
        return responseDto;
    }

    public void cancelRequest(Long requestId, Long userId) {
        RentalRequest request = rentalRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Request not found"));
        
        if (!request.getTenantId().equals(userId)) {
            throw new IllegalStateException("Bạn không có quyền hủy yêu cầu này");
        }
        
        if (request.getStatus() == RequestStatus.REJECTED) {
            throw new IllegalStateException("Yêu cầu này đã bị từ chối hoặc đã hủy.");
        }

        RequestStatus previousStatus = request.getStatus();
        request.setStatus(RequestStatus.REJECTED);
        rentalRequestRepository.save(request);

        if (previousStatus == RequestStatus.APPROVED_WAITING_HANDOVER) {
            Room room = roomRepository.findById(request.getRoomId()).orElse(null);
            if (room != null) {
                if (room.getStatus() == com.stayhub.api.entity.RoomStatus.CHO_DUYET || room.getStatus() == com.stayhub.api.entity.RoomStatus.NGHIEM_THU) {
                    room.setStatus(com.stayhub.api.entity.RoomStatus.TRONG);
                    room.setActiveOtpCode(null);
                    room.setOtpExpiredAt(null);
                    room.setLockedUntil(null);
                    roomRepository.save(room);

                    // Cancel any pending contracts created for this room for this specific tenant
                    List<com.stayhub.api.entity.Contract> pendingContracts = contractRepository.findByRoomIdAndStatus(room.getId(), com.stayhub.api.entity.ContractStatus.PENDING);
                    for (com.stayhub.api.entity.Contract c : pendingContracts) {
                        if (c.getTenantId() != null && c.getTenantId().equals(userId)) {
                            c.setStatus(com.stayhub.api.entity.ContractStatus.CANCELLED);
                            contractRepository.save(c);
                        }
                    }
                }
            }
        }
    }

    @Transactional
    public RentalRequestResponseDto payDeposit(Long requestId) {
        RentalRequest request = rentalRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Yêu cầu thuê không tồn tại"));

        if (request.getStatus() != RequestStatus.PENDING) {
            throw new IllegalArgumentException("Trạng thái yêu cầu không hợp lệ để đóng cọc");
        }

        request.setStatus(RequestStatus.APPROVED_WAITING_HANDOVER);
        rentalRequestRepository.save(request);

        Room room = roomRepository.findById(request.getRoomId())
                .orElseThrow(() -> new IllegalArgumentException("Phòng không tồn tại"));

        if (room.getBranchId() != null) {
            Branch branch = branchRepository.findById(room.getBranchId()).orElse(null);
            if (branch != null) {
                String metadataStr = "{\"actionUrl\":\"/v1/rental-requests/" + request.getId() + "/handover\"}";
                notificationService.send(
                        request.getTenantId(),
                        branch.getOwnerId(),
                        com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                        "Đã đóng tiền cọc",
                        "Khách hàng đã thanh toán cọc cho " + room.getRoomName(),
                        com.stayhub.api.entity.NotificationType.GENERAL,
                        request.getId(),
                        true,
                        com.stayhub.api.entity.NotificationActionStatus.PENDING,
                        metadataStr
                );
            }
        }

        return mapToResponseDto(request);
    }

    public List<RentalRequestResponseDto> getPendingRequestsByOwner(Long ownerId) {
        // Find rooms owned by owner, then requests with status PENDING
        List<Room> rooms = roomRepository.findByOwnerId(ownerId);
        if (rooms == null || rooms.isEmpty()) {
            return new ArrayList<>();
        }
        List<Long> roomIds = rooms.stream().map(Room::getId).collect(Collectors.toList());
        
        List<RentalRequest> pendingRequests = rentalRequestRepository.findAllByRoomIdInAndStatus(roomIds, RequestStatus.PENDING);
        
        return pendingRequests.stream()
                .map(this::mapToResponseDto)
                .collect(Collectors.toList());
    }

    public List<RentalRequest> getAll() {
        return rentalRequestRepository.findAll();
    }

    public RentalRequestResponseDto getLatestRequestByTenant(Long tenantId) {
        RentalRequest request = rentalRequestRepository.findTopByTenantIdOrderBySubmittedAtDesc(tenantId);
        if (request == null) return null;
        return mapToResponseDto(request);
    }

    private RentalRequestResponseDto mapToResponseDto(RentalRequest request) {
        User tenant = userRepository.findById(request.getTenantId()).orElse(new User());
        Room room = roomRepository.findById(request.getRoomId()).orElse(new Room());
        String branchName = "";
        if (request.getBranchId() != null) {
            Branch branch = branchRepository.findById(request.getBranchId()).orElse(null);
            if (branch != null) {
                branchName = branch.getBranchName();
            }
        }
        
        return RentalRequestResponseDto.builder()
                .id(request.getId())
                .tenantId(request.getTenantId())
                .tenantName(tenant.getName())
                .phone(tenant.getPhoneNumber())
                .roomId(request.getRoomId())
                .roomName(room.getRoomName())
                .branchId(request.getBranchId())
                .branchName(branchName)
                .moveInDate(request.getMoveInDate())
                .note(request.getNote())
                .status(request.getStatus())
                .submittedAt(request.getSubmittedAt())
                .build();
    }

    // SSE management
    public SseEmitter registerEmitter(Long ownerId) {
        SseEmitter emitter = new SseEmitter(0L); com.stayhub.api.service.SseHeartbeatService.register(emitter); // no timeout
        emitters.computeIfAbsent(ownerId, k -> new java.util.concurrent.CopyOnWriteArrayList<>()).add(emitter);
        emitter.onCompletion(() -> removeEmitter(ownerId, emitter));
        emitter.onTimeout(() -> removeEmitter(ownerId, emitter));
        return emitter;
    }

    private void removeEmitter(Long ownerId, SseEmitter emitter) {
        List<SseEmitter> list = emitters.get(ownerId);
        if (list != null) {
            list.remove(emitter);
        }
    }

    private void notifyOwner(Long ownerId, RentalRequestResponseDto request) {
        List<SseEmitter> list = emitters.get(ownerId);
        if (list != null) {
            List<SseEmitter> deadEmitters = new ArrayList<>();
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event()
                            .name("rental-request")
                            .data(request));
                } catch (Exception e) {
                    // Record failing emitter
                    deadEmitters.add(emitter);
                }
            }
            list.removeAll(deadEmitters);
        }
    }
}
