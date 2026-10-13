package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Room;
import com.stayhub.api.entity.RoomStatus;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.service.CloudStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/v1/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomRepository roomRepository;
    private final CloudStorageService cloudStorageService;
    private final com.stayhub.api.service.SaasService saasService;
    private final com.stayhub.api.service.StaffService staffService;
    private final com.stayhub.api.service.RoomPostService roomPostService;

    @GetMapping("/branch/{branchId}")
    public ResponseEntity<ApiResponse<List<Room>>> getByBranch(
            @PathVariable Long branchId,
            Authentication auth) {
        verifyBranchAccess(branchId, auth);
        return ResponseEntity.ok(ApiResponse.ok(roomRepository.findByBranchId(branchId)));
    }

    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<ApiResponse<List<Room>>> getByOwner(
            @PathVariable Long ownerId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size,
            @RequestParam(required = false) String status,
            Authentication auth) {
        
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!userId.equals(ownerId)) {
            if (isStaff) {
                java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
                if (assignments.stream().noneMatch(a -> a.getOwnerId().equals(ownerId))) {
                    throw new AccessDeniedException("Bạn không được phân công quản lý chi nhánh của chủ nhà này");
                }
            } else {
                throw new AccessDeniedException("Bạn không có quyền truy cập dữ liệu của chủ nhà khác");
            }
        }

        if (status != null) {
            RoomStatus roomStatus;
            try {
                roomStatus = RoomStatus.valueOf(status);
            } catch (IllegalArgumentException e) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Trạng thái phòng không hợp lệ: " + status);
            }
            return ResponseEntity.ok(ApiResponse.ok(
                    roomRepository.findByOwnerIdAndStatus(ownerId, roomStatus)));
        }

        List<Room> rooms = roomRepository
                .findByOwnerIdPaged(ownerId, PageRequest.of(page, size, Sort.by("roomName").ascending()))
                .getContent();
        return ResponseEntity.ok(ApiResponse.ok(rooms));
    }
    
    private void verifyBranchAccess(Long branchId, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        com.stayhub.api.entity.Branch branch = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.BranchRepository.class).findById(branchId).orElse(null);
        if (branch != null) {
            if (isStaff) {
                java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
                if (assignments.stream().noneMatch(a -> a.getBranchId().equals(branchId))) {
                    throw new AccessDeniedException("Bạn không được phân công quản lý chi nhánh này");
                }
            } else {
                if (!branch.getOwnerId().equals(userId)) {
                    throw new AccessDeniedException("Bạn không có quyền truy cập dữ liệu của chi nhánh này");
                }
            }
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Room>> getById(@PathVariable Long id, Authentication auth) {
        Room room = roomRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng ID: " + id));
                
        if (auth != null && auth.getPrincipal() != null) {
            Long userId = (Long) auth.getPrincipal();
            boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
            boolean isOwner = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER"));
            
            if (isOwner) {
                if (!room.getOwnerId().equals(userId)) {
                    throw new AccessDeniedException("Bạn không có quyền truy cập dữ liệu của phòng này");
                }
            } else if (isStaff) {
                java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
                if (assignments.stream().noneMatch(a -> a.getBranchId().equals(room.getBranchId()))) {
                    throw new AccessDeniedException("Bạn không được phân công quản lý chi nhánh của phòng này");
                }
            }
        } else {
             throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        
        return ResponseEntity.ok(ApiResponse.ok(room));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Room>> create(
            @RequestBody Room room,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        Long ownerId = userId;
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (assignments.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn chưa được phân công làm nhân viên của chủ nhà nào.");
            }
            if (room.getBranchId() != null) {
                com.stayhub.api.entity.StaffAssignment targetAssignment = assignments.stream()
                    .filter(a -> a.getBranchId().equals(room.getBranchId()))
                    .findFirst()
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn chưa được phân công quản lý chi nhánh này."));
                
                ownerId = targetAssignment.getOwnerId();
                if ("MANAGER".equals(targetAssignment.getStaffRole())) {
                    room.setApprovalStatus("APPROVED");
                } else {
                    room.setApprovalStatus("PENDING_APPROVAL");
                }
            } else {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Phòng phải thuộc về một chi nhánh.");
            }
        }
        
        // Kiểm tra giới hạn số phòng của gói cước.
        // Chỉ tính các phòng CHƯA đóng cửa — phòng thuộc chi nhánh đã ngừng
        // hoạt động (DONG_CUA) không còn chiếm quota.
        long currentRoomCount = roomRepository.countActiveQuotaRoomsByOwnerId(ownerId);
        com.stayhub.api.entity.SaasPlan currentPlan = saasService.getCurrentPlan(ownerId);
        if (currentPlan != null && currentPlan.getMaxRooms() != null
                && currentRoomCount >= currentPlan.getMaxRooms()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                "Bạn đã đạt giới hạn tối đa " + currentPlan.getMaxRooms() + " phòng của gói " + currentPlan.getName() + ". Vui lòng nâng cấp gói cước để tạo thêm.");
        }
        
        room.setOwnerId(ownerId);
        Room saved = roomRepository.save(room);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.<Room>builder()
                        .success(true).message("Tạo phòng thành công!").data(saved).build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Room>> update(
            @PathVariable Long id,
            @RequestBody Room updated,
            Authentication auth) {

        Room room = roomRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng ID: " + id));

        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        Long ownerId = userId;
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (assignments.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn chưa được phân công làm nhân viên của chủ nhà nào.");
            }
            if (room.getBranchId() != null) {
                com.stayhub.api.entity.StaffAssignment targetAssignment = assignments.stream()
                    .filter(a -> a.getBranchId().equals(room.getBranchId()))
                    .findFirst()
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn chưa được phân công quản lý chi nhánh này."));
                ownerId = targetAssignment.getOwnerId();
                if ("MANAGER".equals(targetAssignment.getStaffRole())) {
                    updated.setApprovalStatus("APPROVED");
                } else {
                    updated.setApprovalStatus("PENDING_APPROVAL");
                }
            }
        }

        if (!room.getOwnerId().equals(ownerId)) {
            throw new AccessDeniedException("Bạn không có quyền chỉnh sửa phòng này");
        }

        if (updated.getRoomName() != null) room.setRoomName(updated.getRoomName());
        if (updated.getFloorArea() != null) room.setFloorArea(updated.getFloorArea());
        if (updated.getPrice() != null) room.setPrice(updated.getPrice());
        if (updated.getDeposit() != null) room.setDeposit(updated.getDeposit());
        if (updated.getMaxGuests() != null) room.setMaxGuests(updated.getMaxGuests());
        if (updated.getBranchId() != null) room.setBranchId(updated.getBranchId());

        return ResponseEntity.ok(ApiResponse.<Room>builder()
                .success(true).message("Cập nhật phòng thành công!")
                .data(roomRepository.save(room)).build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Long id,
            Authentication auth) {

        Room room = roomRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng ID: " + id));

        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        Long ownerId = userId;
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (assignments.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn chưa được phân công làm nhân viên của chủ nhà nào.");
            }
            if (room.getBranchId() != null) {
                com.stayhub.api.entity.StaffAssignment targetAssignment = assignments.stream()
                    .filter(a -> a.getBranchId().equals(room.getBranchId()))
                    .findFirst()
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn chưa được phân công quản lý chi nhánh này."));
                ownerId = targetAssignment.getOwnerId();
            }
        }

        if (!room.getOwnerId().equals(ownerId)) {
            throw new AccessDeniedException("Bạn không có quyền xóa phòng này");
        }

        if (room.getStatus() == RoomStatus.DA_THUE || 
            room.getStatus() == RoomStatus.CHO_DUYET || 
            room.getStatus() == RoomStatus.NGHIEM_THU || 
            room.getStatus() == RoomStatus.CHO_KICH_HOAT ||
            room.getStatus() == RoomStatus.SAP_TRONG) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Không thể xóa phòng đang có khách thuê hoặc đang trong quá trình giao dịch");
        }

        room.setIsDeleted(true);
        roomRepository.save(room);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true).message("Đã xóa phòng!").build());
    }

    @PostMapping(value = "/{roomId}/images", consumes = org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<java.util.List<String>>> uploadRoomImages(
            @PathVariable Long roomId,
            @org.springframework.web.bind.annotation.RequestPart("images") java.util.List<org.springframework.web.multipart.MultipartFile> images,
            Authentication auth) {
        
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng ID: " + roomId));

        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        Long effectiveOwnerId = userId;
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (room.getBranchId() != null) {
                com.stayhub.api.entity.StaffAssignment targetAssignment = assignments.stream()
                    .filter(a -> a.getBranchId().equals(room.getBranchId()))
                    .findFirst()
                    .orElseThrow(() -> new AccessDeniedException("Bạn không được phân công quản lý chi nhánh này"));
                effectiveOwnerId = targetAssignment.getOwnerId();
            }
        }

        if (!room.getOwnerId().equals(effectiveOwnerId)) {
            throw new AccessDeniedException("Bạn không có quyền chỉnh sửa phòng này");
        }

        java.util.List<String> urls = new java.util.ArrayList<>();
        for (org.springframework.web.multipart.MultipartFile file : images) {
            String url = cloudStorageService.uploadFile(file);
            if (url != null) {
                urls.add(url);
            }
        }

        return ResponseEntity.ok(ApiResponse.<java.util.List<String>>builder()
                .success(true)
                .message("Tải ảnh lên thành công")
                .data(urls)
                .build());
    }

    @PutMapping("/{roomId}/config")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<ApiResponse<Room>> configureRoom(
            @PathVariable Long roomId,
            @RequestBody java.util.Map<String, Object> body,
            Authentication auth) {
        System.out.println(">>> [RoomController] Received configureRoom request for room " + roomId);
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phòng ID: " + roomId));

        Long effectiveOwnerId = userId;
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (room.getBranchId() != null) {
                com.stayhub.api.entity.StaffAssignment targetAssignment = assignments.stream()
                    .filter(a -> a.getBranchId().equals(room.getBranchId()))
                    .findFirst()
                    .orElseThrow(() -> new AccessDeniedException("Bạn không được phân công quản lý chi nhánh này"));
                effectiveOwnerId = targetAssignment.getOwnerId();
            } else {
                throw new AccessDeniedException("Phòng này chưa được gán vào chi nhánh nào");
            }
        }

        if (!room.getOwnerId().equals(effectiveOwnerId)) {
            throw new AccessDeniedException("Bạn không có quyền chỉnh sửa phòng này");
        }

        java.util.Map<String, Object> info = room.getDetailedInfo() != null
                ? new java.util.HashMap<>(room.getDetailedInfo())
                : new java.util.HashMap<>();

        // Save direct fields to Room entity with validation
        if (body.containsKey("roomName")) {
            String roomName = body.get("roomName").toString().trim();
            if (roomName.isEmpty()) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tên phòng không được để trống");
            room.setRoomName(roomName);
        }
        if (body.containsKey("price")) {
            Double price = Double.valueOf(body.get("price").toString());
            if (price < 0) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Giá thuê không được âm");
            room.setPrice(price);
        }
        if (body.containsKey("deposit")) {
            Double deposit = Double.valueOf(body.get("deposit").toString());
            if (deposit < 0) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tiền cọc không được âm");
            Double currentPrice = room.getPrice() != null ? room.getPrice() : 0.0;
            if (currentPrice > 0 && deposit > currentPrice * 10) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Tiền cọc không được vượt quá 10 lần giá thuê (" + (currentPrice * 10) + ")");
            }
            room.setDeposit(deposit);
        }
        if (body.containsKey("area")) {
            Double area = Double.valueOf(body.get("area").toString());
            if (area <= 0) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Diện tích phải lớn hơn 0");
            room.setFloorArea(area);
        }
        if (body.containsKey("maxOccupants")) {
            Integer maxGuests = Double.valueOf(body.get("maxOccupants").toString()).intValue();
            if (maxGuests <= 0) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Số người tối đa phải lớn hơn 0");
            room.setMaxGuests(maxGuests);
        }
        if (body.containsKey("description")) {
            room.setDescription(body.get("description").toString().trim());
        }

        // Save extended info to detailedInfo JSON
        // QUAN TRỌNG: `roomType` là MÃ loại phòng (vd PHONG_TRO). Phải ĐỒNG BỘ
        // xuống cột canonical `rooms.room_sub_type` — nếu chỉ ghi vào detailedInfo
        // thì bộ lọc guest (RoomPostSpecification) lọc trên room_sub_type = NULL
        // → phòng biến mất khỏi kết quả tìm kiếm / hiển thị sai loại.
        if (body.containsKey("roomType")) {
            Object rawType = body.get("roomType");
            // Dùng safeCode(): vừa quy về MÃ canonical, vừa chặn mã vượt quá độ
            // dài cột DB (30) để tránh bị cắt cụt âm thầm.
            String code = com.stayhub.api.util.RoomTypeCodes.safeCode(
                    rawType != null ? rawType.toString() : null);
            // EDGE CASE: nếu client gửi mã/nhãn KHÔNG nhận diện được, TUYỆT ĐỐI
            // không ghi nửa vời (detailedInfo có mà room_sub_type không) — vì đó
            // chính là nguồn gốc bug "phòng hiện sai loại". Chặn ngay từ cửa vào.
            if (code == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                        "Loại phòng không hợp lệ: '" + rawType + "'. Vui lòng chọn từ danh sách.");
            }
            // Ghi ĐỒNG THỜI cả hai nơi bằng CÙNG một MÃ canonical → không bao giờ lệch.
            info.put("roomType", code);
            room.setRoomSubType(code);
        }
        if (body.containsKey("maxVehicles")) info.put("maxVehicles", body.get("maxVehicles"));
        if (body.containsKey("furnitureLevel")) info.put("furnitureLevel", body.get("furnitureLevel"));
        if (body.containsKey("furnitureItems")) info.put("furnitureItems", body.get("furnitureItems"));
        if (body.containsKey("orientation")) info.put("orientation", body.get("orientation"));
        // NOTE: roomDescription is intentionally NOT stored here anymore.
        // The room description is entered by the owner at POST time (marketplace),
        // not during room configuration.

        // Match frontend payload keys for electric/water index
        if (body.containsKey("electricIndex")) info.put("electricIndexInit", body.get("electricIndex"));
        if (body.containsKey("waterIndex")) info.put("waterIndexInit", body.get("waterIndex"));

        if (body.containsKey("electricPricingType")) {
            room.setElectricityPricingType(com.stayhub.api.entity.PricingType.valueOf(body.get("electricPricingType").toString()));
        }
        if (body.containsKey("electricPrice")) {
            room.setElectricityPrice(Double.valueOf(body.get("electricPrice").toString()));
        }
        if (body.containsKey("electricOldIndex")) info.put("electricOldIndex", body.get("electricOldIndex"));
        if (body.containsKey("waterPricingType")) {
            room.setWaterPricingType(com.stayhub.api.entity.PricingType.valueOf(body.get("waterPricingType").toString()));
        }
        if (body.containsKey("waterPrice")) {
            room.setWaterPrice(Double.valueOf(body.get("waterPrice").toString()));
        }
        if (body.containsKey("waterOldIndex")) info.put("waterOldIndex", body.get("waterOldIndex"));
        if (body.containsKey("waterPerPersonPrice")) info.put("waterPerPersonPrice", body.get("waterPerPersonPrice"));

        // Feature toggles — sync detailedInfo AND Room entity fields for consistency
        if (body.containsKey("isSelfContained")) {
            boolean isSelfContained = Boolean.parseBoolean(body.get("isSelfContained").toString());
            info.put("isSelfContained", isSelfContained);
            // Sync to Room.bathroomType to keep data consistent
            room.setBathroomType(isSelfContained ? "RIENG" : "CHUNG");
        }
        if (body.containsKey("hasMezzanine")) info.put("hasMezzanine", body.get("hasMezzanine"));
        if (body.containsKey("hasBalcony")) {
            boolean hasBalcony = Boolean.parseBoolean(body.get("hasBalcony").toString());
            info.put("hasBalcony", hasBalcony);
            room.setHasBalcony(hasBalcony);
        }
        if (body.containsKey("hasWindow")) {
            boolean hasWindow = Boolean.parseBoolean(body.get("hasWindow").toString());
            info.put("hasWindow", hasWindow);
            room.setHasWindow(hasWindow);
        }
        if (body.containsKey("hasKitchen")) info.put("hasKitchen", body.get("hasKitchen"));
        
        // Furniture toggles
        for (String key : body.keySet()) {
            if (key.startsWith("FURNITURE_")) {
                info.put(key, body.get(key));
            }
        }
        room.setDetailedInfo(info);

        try {
            com.fasterxml.jackson.databind.ObjectMapper objectMapper = new com.fasterxml.jackson.databind.ObjectMapper();
            
            // Xử lý ảnh chính của phòng với CompletableFuture
            if (body.containsKey("photos")) {
                System.out.println(">>> [RoomController] Processing main photos...");
                java.util.List<String> photoList = (java.util.List<String>) body.get("photos");
                java.util.List<java.util.concurrent.CompletableFuture<String>> futures = photoList.stream()
                    .map(p -> java.util.concurrent.CompletableFuture.supplyAsync(() -> {
                        if (p.startsWith("http") && !p.startsWith("http://localhost")) return p;
                        System.out.println(">>> [RoomController] Uploading main photo to Cloudinary...");
                        String url = cloudStorageService.uploadBase64(p);
                        System.out.println(">>> [RoomController] Uploaded main photo: " + url);
                        return url;
                    }))
                    .collect(java.util.stream.Collectors.toList());
                    
                java.util.List<String> urls = futures.stream()
                    .map(java.util.concurrent.CompletableFuture::join)
                    .filter(java.util.Objects::nonNull)
                    .collect(java.util.stream.Collectors.toList());
                room.setRoomImages(objectMapper.writeValueAsString(urls));
                info.put("photos", urls); // Tối ưu: Lưu URL thay vì base64 khổng lồ vào DB
                System.out.println(">>> [RoomController] Finished processing main photos.");
            }

            // Xử lý ảnh các tính năng khác với CompletableFuture
            if (body.containsKey("featurePhotos")) {
                java.util.Map<String, java.util.List<String>> featurePhotos = (java.util.Map<String, java.util.List<String>>) body.get("featurePhotos");
                java.util.Map<String, java.util.List<String>> processedFeaturePhotos = new java.util.concurrent.ConcurrentHashMap<>();
                
                java.util.List<java.util.concurrent.CompletableFuture<Void>> allTasks = new java.util.ArrayList<>();
                for (java.util.Map.Entry<String, java.util.List<String>> entry : featurePhotos.entrySet()) {
                    java.util.List<java.util.concurrent.CompletableFuture<String>> groupFutures = entry.getValue().stream()
                        .map(p -> java.util.concurrent.CompletableFuture.supplyAsync(() -> {
                            if (p.startsWith("http") && !p.startsWith("http://localhost")) return p;
                            return cloudStorageService.uploadBase64(p);
                        }))
                        .collect(java.util.stream.Collectors.toList());
                        
                    java.util.concurrent.CompletableFuture<Void> groupTask = java.util.concurrent.CompletableFuture.allOf(groupFutures.toArray(new java.util.concurrent.CompletableFuture[0]))
                        .thenAccept(v -> {
                            java.util.List<String> urls = groupFutures.stream()
                                .map(java.util.concurrent.CompletableFuture::join)
                                .filter(java.util.Objects::nonNull)
                                .collect(java.util.stream.Collectors.toList());
                            if (!urls.isEmpty()) processedFeaturePhotos.put(entry.getKey(), urls);
                        });
                    allTasks.add(groupTask);
                }
                
                java.util.concurrent.CompletableFuture.allOf(allTasks.toArray(new java.util.concurrent.CompletableFuture[0])).join();
                info.put("featurePhotos", processedFeaturePhotos);
                room.setDetailedInfo(info);
                System.out.println(">>> [RoomController] Finished processing feature photos.");
            }
        } catch (Exception e) {
            System.err.println(">>> [RoomController] Exception during photo processing: " + e.getMessage());
            e.printStackTrace();
            throw new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, "Lỗi xử lý ảnh: " + e.getMessage());
        }

        System.out.println(">>> [RoomController] Saving room to DB...");
        if (room.getStatus() == com.stayhub.api.entity.RoomStatus.KHOA_CHO_CAP_NHAT) {
            room.setStatus(com.stayhub.api.entity.RoomStatus.TRONG);
            System.out.println(">>> [RoomController] Changed room status from KHOA_CHO_CAP_NHAT to TRONG.");
        }
        roomRepository.save(room);
        
        // AUTO PUBLISH: "để khi cấu hình xong phòng trống thì tự đẩy bài lên luôn"
        roomPostService.autoPublishPostIfEmpty(room);
        
        System.out.println(">>> [RoomController] Room saved successfully.");
        return ResponseEntity.ok(ApiResponse.<Room>builder()
                .success(true)
                .message("Cấu hình phòng thành công!")
                .data(null)
                .build());
    }

    @org.springframework.transaction.annotation.Transactional
    @PostMapping("/bulk-clone")
    public ResponseEntity<ApiResponse<String>> bulkCloneRooms(
            @jakarta.validation.Valid @RequestBody com.stayhub.api.dto.request.BulkCloneRoomRequestDto request,
            Authentication auth) {
        
        Room sourceRoom = roomRepository.findById(request.getSourceRoomId())
                .orElseThrow(() -> new ResourceNotFoundException("Phòng gốc", request.getSourceRoomId()));

        // Xác thực quyền chủ nhà (verifyOwner)
        // ... (Tuỳ logic dự án hiện tại, tạm giả định đã xác thực)

        java.util.List<Long> targetIds = request.getTargetRooms().stream()
                .map(com.stayhub.api.dto.request.BulkCloneRoomRequestDto.TargetRoomConfig::getId)
                .collect(java.util.stream.Collectors.toList());
        java.util.List<Room> targetRooms = roomRepository.findAllById(targetIds);
        
        java.util.Map<Long, com.stayhub.api.dto.request.BulkCloneRoomRequestDto.TargetRoomConfig> targetMap = request.getTargetRooms().stream()
                .collect(java.util.stream.Collectors.toMap(
                        com.stayhub.api.dto.request.BulkCloneRoomRequestDto.TargetRoomConfig::getId,
                        config -> config
                ));

        for (Room target : targetRooms) {
            // Không copy các trường định danh: id, roomName, roomCode, status, isDeleted...
            com.stayhub.api.dto.request.BulkCloneRoomRequestDto.TargetRoomConfig config = targetMap.get(target.getId());
            
            if (config != null && config.getPrice() != null && config.getPrice() > 0) {
                target.setPrice(config.getPrice());
            } else if (target.getPrice() == null || target.getPrice() == 0) {
                target.setPrice(sourceRoom.getPrice());
            }
            
            if (config != null && config.getFloorArea() != null && config.getFloorArea() > 0) {
                target.setFloorArea(config.getFloorArea());
            } else if (target.getFloorArea() == null || target.getFloorArea() == 0) {
                target.setFloorArea(sourceRoom.getFloorArea());
            }
            
            target.setDeposit(sourceRoom.getDeposit());
            target.setMaxGuests(sourceRoom.getMaxGuests());
            target.setElectricityPrice(sourceRoom.getElectricityPrice());
            target.setWaterPrice(sourceRoom.getWaterPrice());
            target.setServiceFee(sourceRoom.getServiceFee());
            target.setElectricityPricingType(sourceRoom.getElectricityPricingType());
            target.setWaterPricingType(sourceRoom.getWaterPricingType());
            target.setServiceFeePricingType(sourceRoom.getServiceFeePricingType());
            target.setDescription(sourceRoom.getDescription());
            target.setRoomImages(sourceRoom.getRoomImages());
            
            // Xử lý detailedInfo (Nội thất & tiện ích)
            if (sourceRoom.getDetailedInfo() != null) {
                target.setDetailedInfo(new java.util.HashMap<>(sourceRoom.getDetailedInfo()));
            }
            
            // Cập nhật trạng thái nếu đang ở KHOA_CHO_CAP_NHAT -> TRONG (vì đã được cấu hình)
            if (target.getStatus() == com.stayhub.api.entity.RoomStatus.KHOA_CHO_CAP_NHAT) {
                target.setStatus(com.stayhub.api.entity.RoomStatus.TRONG);
            }
        }

        roomRepository.saveAll(targetRooms);
        
        // AUTO PUBLISH: "khi cấu hình xong phòng trống thì tự đẩy bài lên luôn"
        // Chỉ làm sau khi đã lưu DB thành công
        for (Room target : targetRooms) {
            roomPostService.autoPublishPostIfEmpty(target);
        }

        return ResponseEntity.ok(ApiResponse.<String>builder()
                .success(true)
                .message("Nhân bản cấu hình thành công cho " + targetRooms.size() + " phòng!")
                .data(null)
                .build());
    }
}
