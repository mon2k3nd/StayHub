package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.response.NearbyBranchDto;
import com.stayhub.api.entity.Branch;
import com.stayhub.api.entity.Room;
import com.stayhub.api.entity.SharedFacility;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.repository.SharedFacilityRepository;
import com.stayhub.api.service.BranchService;
import com.stayhub.api.service.CloudStorageService;
import com.stayhub.api.service.SaasService;
import com.stayhub.api.repository.BranchRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.stream.Collectors;

import java.util.List;

@RestController
@RequestMapping("/v1/branches")
@lombok.extern.slf4j.Slf4j
public class BranchController {

    private final BranchService branchService;
    private final BranchRepository branchRepository;
    private final RoomRepository roomRepository;
    private final SharedFacilityRepository sharedFacilityRepository;
    private final CloudStorageService cloudStorageService;
    private final ObjectMapper objectMapper;
    private final SaasService saasService;
    private final com.stayhub.api.service.StaffService staffService;

    @jakarta.persistence.PersistenceContext
    private jakarta.persistence.EntityManager entityManager;

    @Autowired
    public BranchController(BranchService branchService,
                            BranchRepository branchRepository,
                            RoomRepository roomRepository,
                            SharedFacilityRepository sharedFacilityRepository,
                            CloudStorageService cloudStorageService,
                            ObjectMapper objectMapper,
                            SaasService saasService,
                            com.stayhub.api.service.StaffService staffService) {
        this.branchService = branchService;
        this.branchRepository = branchRepository;
        this.roomRepository = roomRepository;
        this.sharedFacilityRepository = sharedFacilityRepository;
        this.cloudStorageService = cloudStorageService;
        this.objectMapper = objectMapper;
        this.saasService = saasService;
        this.staffService = staffService;
    }

    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<ApiResponse<List<Branch>>> getByOwner(
            @PathVariable Long ownerId, 
            Authentication auth) {
        verifyBranchOwnerAccess(ownerId, auth);
        return ResponseEntity.ok(ApiResponse.ok(branchService.getByOwner(ownerId)));
    }

    @GetMapping("/owner/{ownerId}/deleted")
    public ResponseEntity<ApiResponse<List<Branch>>> getDeletedByOwner(
            @PathVariable Long ownerId, 
            Authentication auth) {
        verifyBranchOwnerAccess(ownerId, auth);
        return ResponseEntity.ok(ApiResponse.ok(branchService.getDeletedByOwner(ownerId)));
    }

    @GetMapping("/owner/{ownerId}/drafts")
    public ResponseEntity<ApiResponse<List<Branch>>> getDraftsByOwner(
            @PathVariable Long ownerId,
            Authentication auth) {
        verifyBranchOwnerAccess(ownerId, auth);
        return ResponseEntity.ok(ApiResponse.ok(branchService.getDraftsByOwner(ownerId)));
    }

    /**
     * Lấy MỘT chi nhánh theo ID — dùng cho wizard khi cần nạp lại cấu trúc
     * mới nhất (đặc biệt là `description` chứa sơ đồ tầng/phòng/WC do Bước 3
     * ghi). Trước đây wizard chỉ giữ model trong bộ nhớ nên khi bấm "xem lại"
     * có thể hiển thị dữ liệu cũ.
     * GET /v1/branches/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Branch>> getById(
            @PathVariable Long id,
            Authentication auth) {
        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));
        assertBranchAccess(branch, auth, "xem chi nhánh này");
        return ResponseEntity.ok(ApiResponse.<Branch>builder()
                .success(true)
                .data(branch)
                .build());
    }

    /**
     * Lấy RIÊNG ảnh base64 (cover + PCCC) của chi nhánh.
     *
     * <p>Vì {@code coverImages}/{@code pcccImages} đã bị {@code @JsonIgnore} để
     * tránh OOM khi trả danh sách, màn SỬA chi nhánh gọi endpoint này để nạp ảnh.
     * GET /v1/branches/{id}/images
     */
    @GetMapping("/{id}/images")
    public ResponseEntity<ApiResponse<java.util.Map<String, String>>> getImages(
            @PathVariable Long id,
            Authentication auth) {
        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));
        assertBranchAccess(branch, auth, "xem ảnh chi nhánh này");
        java.util.Map<String, String> data = new java.util.HashMap<>();
        data.put("coverImage", branch.getCoverImage());
        data.put("coverImages", branch.getCoverImages());
        data.put("pcccImages", branch.getPcccImages());
        return ResponseEntity.ok(ApiResponse.<java.util.Map<String, String>>builder()
                .success(true)
                .data(data)
                .build());
    }

    private void verifyBranchOwnerAccess(Long ownerId, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (!userId.equals(ownerId)) {
            if (isStaff) {
                java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
                if (assignments.stream().noneMatch(a -> a.getOwnerId().equals(ownerId))) {
                    throw new org.springframework.security.access.AccessDeniedException("Bạn không được phân công quản lý chi nhánh của chủ nhà này");
                }
            } else {
                throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền truy cập dữ liệu của chủ nhà khác");
            }
        }
    }

    /**
     * Kiểm tra mã dãy trọ có bị trùng không (chỉ tính các branch đang active).
     * GET /v1/branches/check-code?code=H5_351CAUGIAY&excludeId=5
     */
    @GetMapping("/check-code")
    public ResponseEntity<ApiResponse<java.util.Map<String, Object>>> checkBranchCode(
            @RequestParam String code,
            @RequestParam(required = false) Long excludeId) {
        boolean exists = branchService.isBranchCodeTaken(code, excludeId);
        java.util.Map<String, Object> data = new java.util.HashMap<>();
        data.put("taken", exists);
        if (exists) {
            // Tra ve thong tin chi nhanh dang chiem ma de frontend hien thi
            // dung "ai dang giu ma nay" thay vi chi bao trung chung chung.
            Branch conflicting = branchService.findConflictingBranch(code, excludeId);
            if (conflicting != null) {
                data.put("conflictingId", conflicting.getId());
                data.put("conflictingName", conflicting.getBranchName());
                data.put("conflictingCode", conflicting.getBranchCode());
                data.put("conflictingStatus", conflicting.getCreationStatus());
            }
        }
        return ResponseEntity.ok(ApiResponse.<java.util.Map<String, Object>>builder()
                .success(true)
                .data(data)
                .build());
    }

    /**
     * Tìm chi nhánh gần vị trí người dùng.
     * GET /v1/branches/nearby?lat=21.03&lng=105.84&radius=5&limit=20
     * - radius: bán kính tìm kiếm (km), mặc định 5km
     * - limit: số lượng kết quả tối đa, mặc định 20
     */
    @GetMapping("/nearby")
    public ResponseEntity<ApiResponse<List<NearbyBranchDto>>> getNearbyBranches(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "5") double radius,
            @RequestParam(defaultValue = "20") int limit) {
        List<NearbyBranchDto> result = branchService.getNearbyBranches(lat, lng, radius, limit);
        return ResponseEntity.ok(ApiResponse.<List<NearbyBranchDto>>builder()
                .success(true)
                .data(result)
                .build());
    }

    /**
     * Lấy danh sách phòng theo chi nhánh - dùng cho màn hình cấu hình chi tiết.
     * GET /v1/branches/{branchId}/rooms
     */
    @GetMapping("/{branchId}/rooms")
    public ResponseEntity<ApiResponse<List<Room>>> getRoomsByBranch(
            @PathVariable Long branchId,
            Authentication auth) {
        List<Room> rooms = roomRepository.findByBranchId(branchId);
        return ResponseEntity.ok(ApiResponse.<List<Room>>builder()
                .success(true)
                .data(rooms)
                .build());
    }

    /**
     * Lấy danh sách WC chung theo chi nhánh.
     * GET /v1/branches/{branchId}/facilities
     *
     * <p>Tự phục hồi (self-heal): nếu description của chi nhánh còn lưu
     * {@code sharedWcs} (do Bước 3 ghi) nhưng bảng {@code shared_facilities}
     * không còn bản ghi WC nào (hậu quả của lỗi xoá nhầm trước đây), ta tạo lại
     * các WC từ description để Bước 4 hiển thị được cấu hình WC.</p>
     */
    @GetMapping("/{branchId}/facilities")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<ApiResponse<List<SharedFacility>>> getFacilitiesByBranch(
            @PathVariable Long branchId,
            Authentication auth) {
        List<SharedFacility> facilities = sharedFacilityRepository.findByBranchId(branchId);

        // Tự phục hồi: tạo lại WC đã mất VÀ khôi phục liên kết phòng ↔ WC.
        // Chạy cả khi WC đã tồn tại nhưng bảng nối rỗng (mất liên kết).
        facilities = selfHealWcsFromDescription(branchId, facilities);

        return ResponseEntity.ok(ApiResponse.<List<SharedFacility>>builder()
                .success(true)
                .data(facilities)
                .build());
    }

    /**
     * Tạo lại các WC chung từ {@code description.sharedWcs} nếu chúng đã bị mất,
     * đồng thời khôi phục liên kết phòng ↔ WC từ {@code floors[].rooms[].sharedWcId}.
     * Trả về danh sách facility đã cập nhật (gồm cả ASSET cũ + WC mới tạo).
     */
    private List<SharedFacility> selfHealWcsFromDescription(
            Long branchId, List<SharedFacility> existing) {
        try {
            Branch branch = branchRepository.findById(branchId).orElse(null);
            if (branch == null || branch.getDescription() == null) return existing;
            String desc = branch.getDescription();
            if (!desc.contains("\"sharedWcs\"")) return existing;

            com.fasterxml.jackson.databind.JsonNode meta = objectMapper.readTree(desc);
            if (!meta.has("sharedWcs") || !meta.get("sharedWcs").isArray()) return existing;

            List<SharedFacility> result = new java.util.ArrayList<>(existing);
            java.util.Map<String, Long> wcIdByTempId = new java.util.HashMap<>();
            for (com.fasterxml.jackson.databind.JsonNode wcNode : meta.get("sharedWcs")) {
                String tempId = wcNode.has("tempId") ? wcNode.get("tempId").asText()
                        : (wcNode.has("code") ? wcNode.get("code").asText() : null);
                if (tempId == null || tempId.isBlank()) continue;
                // Bỏ qua nếu đã tồn tại (theo notes = tempId).
                SharedFacility found = result.stream()
                        .filter(f -> tempId.equals(f.getNotes()))
                        .findFirst().orElse(null);
                if (found != null) {
                    wcIdByTempId.put(tempId, found.getId());
                    continue;
                }

                String name = wcNode.has("name") ? wcNode.get("name").asText() : tempId;
                SharedFacility wc = SharedFacility.builder()
                        .branchId(branchId)
                        .name(name)
                        .type("WC")
                        .notes(tempId)
                        .build();
                wc = sharedFacilityRepository.save(wc);
                result.add(wc);
                wcIdByTempId.put(tempId, wc.getId());
            }

            // Khôi phục liên kết phòng ↔ WC từ floors[].rooms[].sharedWcId.
            if (meta.has("floors") && meta.get("floors").isArray()) {
                List<Room> rooms = roomRepository.findByBranchId(branchId);
                for (com.fasterxml.jackson.databind.JsonNode fNode : meta.get("floors")) {
                    if (!fNode.has("rooms") || !fNode.get("rooms").isArray()) continue;
                    for (com.fasterxml.jackson.databind.JsonNode rNode : fNode.get("rooms")) {
                        String rName = rNode.has("tempId") ? rNode.get("tempId").asText()
                                : (rNode.has("code") ? rNode.get("code").asText() : null);
                        if (rName == null || rName.isBlank()) continue;
                        String wcTempId = rNode.has("sharedWcId") && !rNode.get("sharedWcId").isNull()
                                ? rNode.get("sharedWcId").asText() : null;
                        if (wcTempId == null || wcTempId.isBlank()) continue;
                        Long wcId = wcIdByTempId.get(wcTempId);
                        if (wcId == null) continue;

                        String rCode = branch.getBranchCode() + "_" + rName;
                        Room room = rooms.stream()
                                .filter(r -> rCode.equals(r.getRoomCode()))
                                .findFirst().orElse(null);
                        if (room == null || room.getId() == null) continue;

                        // Ghi trực tiếp bảng nối (tránh mutate entity gây lỗi hashCode @Data).
                        entityManager.createNativeQuery(
                                "DELETE FROM room_shared_facilities WHERE room_id = :rid")
                            .setParameter("rid", room.getId())
                            .executeUpdate();
                        entityManager.createNativeQuery(
                                "INSERT INTO room_shared_facilities (facility_id, room_id) "
                                    + "VALUES (:fid, :rid)")
                            .setParameter("fid", wcId)
                            .setParameter("rid", room.getId())
                            .executeUpdate();
                    }
                }
            }
            return result;
        } catch (Exception e) {
            // Không chặn API nếu phục hồi thất bại.
            return existing;
        }
    }

    /**
     * Cấu hình chi tiết WC chung.
     * PUT /v1/branches/{branchId}/facilities/{facilityId}/config
     * Body: { "notes": "Lịch dọn thứ 2, 4, 6" }
     */
    @PutMapping("/{branchId}/facilities/{facilityId}/config")
    public ResponseEntity<ApiResponse<SharedFacility>> configureFacility(
            @PathVariable Long branchId,
            @PathVariable Long facilityId,
            @RequestBody java.util.Map<String, Object> body,
            Authentication auth) {

        if (auth == null || auth.getPrincipal() == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));

        SharedFacility facility = sharedFacilityRepository.findById(facilityId)
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy WC ID: " + facilityId));

        if (!facility.getBranchId().equals(branchId)) {
            throw new IllegalArgumentException("WC không thuộc chi nhánh này");
        }
        
        Branch branch = branchRepository.findById(branchId).orElse(null);
        if (branch != null) {
            if (isStaff) {
                java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
                if (assignments.stream().noneMatch(a -> a.getBranchId().equals(branchId))) {
                    throw new org.springframework.security.access.AccessDeniedException("Bạn không được phân công quản lý chi nhánh này");
                }
            } else {
                if (!branch.getOwnerId().equals(userId)) {
                    throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền thay đổi cấu hình tiện ích của chi nhánh này");
                }
            }
        }

        if (body.containsKey("name")) {
            facility.setName((String) body.get("name"));
        }
        if (body.containsKey("notes")) {
            facility.setNotes((String) body.get("notes"));
        }
        if (body.containsKey("equipment")) {
            try {
                facility.setEquipment(objectMapper.writeValueAsString(body.get("equipment")));
            } catch (Exception ignored) { log.warn("Ignored exception: ", ignored); }
        }
        if (body.containsKey("images")) {
            try {
                java.util.List<String> photoList = (java.util.List<String>) body.get("images");
                java.util.List<java.util.concurrent.CompletableFuture<String>> futures = photoList.stream()
                    .map(p -> java.util.concurrent.CompletableFuture.supplyAsync(() -> {
                        if (p.startsWith("http") && !p.startsWith("http://localhost")) return p;
                        return cloudStorageService.uploadBase64(p);
                    }))
                    .collect(java.util.stream.Collectors.toList());
                java.util.concurrent.CompletableFuture.allOf(futures.toArray(new java.util.concurrent.CompletableFuture[0])).join();
                java.util.List<String> urls = futures.stream()
                    .map(java.util.concurrent.CompletableFuture::join)
                    .filter(java.util.Objects::nonNull)
                    .collect(java.util.stream.Collectors.toList());
                facility.setImages(objectMapper.writeValueAsString(urls));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        if (body.containsKey("featurePhotos")) {
            try {
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
                facility.setFeaturePhotos(objectMapper.writeValueAsString(processedFeaturePhotos));
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        if (body.containsKey("electricIndex")) {
            Object electricIndex = body.get("electricIndex");
            if (electricIndex instanceof Number) {
                facility.setElectricIndexInit(((Number) electricIndex).intValue());
            } else if (electricIndex instanceof String) {
                facility.setElectricIndexInit(Integer.parseInt((String) electricIndex));
            }
        }
        if (body.containsKey("waterPricingType")) {
            try {
                facility.setWaterPricingType(com.stayhub.api.entity.PricingType.valueOf(body.get("waterPricingType").toString()));
            } catch (Exception ignored) { log.warn("Ignored exception: ", ignored); }
        }
        if (body.containsKey("waterIndex")) {
            Object waterIndex = body.get("waterIndex");
            if (waterIndex instanceof Number) {
                facility.setWaterIndexInit(((Number) waterIndex).intValue());
            } else if (waterIndex instanceof String) {
                facility.setWaterIndexInit(Integer.parseInt((String) waterIndex));
            }
        }
        if (body.containsKey("roomIds")) {
            List<?> roomIds = (List<?>) body.get("roomIds");
            List<Room> rooms = roomRepository.findAllById(
                roomIds.stream()
                    .map(id -> {
                        if (id instanceof Number) return ((Number) id).longValue();
                        return Long.parseLong(id.toString());
                    })
                    .collect(Collectors.toList())
            );
            facility.setRooms(rooms);
        }

        SharedFacility saved = sharedFacilityRepository.save(facility);
        return ResponseEntity.ok(ApiResponse.<SharedFacility>builder()
                .success(true)
                .message("Cập nhật WC chung thành công!")
                .data(saved)
                .build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Long id,
            Authentication auth) {

        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));

        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        Long ownerId = userId;
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (!assignments.isEmpty()) {
                ownerId = assignments.get(0).getOwnerId();
            }
        }

        if (!branch.getOwnerId().equals(ownerId)) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền xóa chi nhánh này");
        }

        // Service tự phân biệt: COMPLETED -> ngừng hoạt động (SUSPENDED + _OFF),
        // DRAFT -> hủy hẳn (xóa cứng, giải phóng mã).
        boolean isDraft = !"COMPLETED".equals(branch.getCreationStatus());
        branchService.delete(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true)
                .message(isDraft ? "Đã hủy chi nhánh đang khởi tạo!" : "Chi nhánh đã chuyển sang trạng thái ngừng hoạt động!")
                .build());
    }

    /**
     * HỦY chi nhánh đang khởi tạo (DRAFT) — xóa cứng, mã được giải phóng
     * hoàn toàn như chưa từng tồn tại.
     */
    @DeleteMapping("/{id}/cancel-draft")
    public ResponseEntity<ApiResponse<Void>> cancelDraft(
            @PathVariable Long id,
            Authentication auth) {

        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));

        assertBranchAccess(branch, auth, "hủy");

        branchService.cancelDraft(id);
        return ResponseEntity.ok(ApiResponse.<Void>builder()
                .success(true).message("Đã hủy chi nhánh đang khởi tạo!").build());
    }

    @PutMapping("/{id}/approve")
    public ResponseEntity<ApiResponse<Branch>> approve(
            @PathVariable Long id,
            @org.springframework.web.bind.annotation.RequestParam boolean approved,
            Authentication auth) {
        
        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));

        Long ownerId = (Long) auth.getPrincipal();
        if (!branch.getOwnerId().equals(ownerId)) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền duyệt chi nhánh này");
        }

        if (approved) {
            branch.setApprovalStatus("APPROVED");
        } else {
            branch.setIsDeleted(true);
        }
        
        return ResponseEntity.ok(ApiResponse.<Branch>builder()
                .success(true).message("Đã xử lý phê duyệt chi nhánh!")
                .data(branchRepository.save(branch)).build());
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Branch>> create(
            @RequestBody Branch branch,
            Authentication auth) {

        Long userId = (Long) auth.getPrincipal();
        Long ownerId = userId;
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (assignments.isEmpty()) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn chưa được phân công làm nhân viên của chủ nhà nào.");
            }
            ownerId = assignments.get(0).getOwnerId();
            boolean isManager = assignments.stream().anyMatch(a -> "MANAGER".equals(a.getStaffRole()));
            if (isManager) {
                branch.setApprovalStatus("APPROVED");
            } else {
                branch.setApprovalStatus("PENDING_APPROVAL");
            }
        }
        
        // Kiểm tra giới hạn số chi nhánh của gói cước.
        // Chỉ tính các chi nhánh CHƯA tạm ngừng — chi nhánh đã ngừng hoạt động
        // không còn chiếm quota nên chủ trọ vẫn tạo được chi nhánh mới.
        long currentBranchCount = branchRepository.countActiveQuotaBranchesByOwnerId(ownerId);
        com.stayhub.api.entity.SaasPlan currentPlan = saasService.getCurrentPlan(ownerId);
        if (currentPlan != null && currentPlan.getMaxBranches() != null
                && currentBranchCount >= currentPlan.getMaxBranches()) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.BAD_REQUEST,
                "Bạn đã đạt giới hạn tối đa " + currentPlan.getMaxBranches() + " chi nhánh của gói " + currentPlan.getName() + ". Vui lòng nâng cấp gói cước để tạo thêm.");
        }

        branch.setOwnerId(ownerId);

        // ── Chống bypass wizard 5 bước ──
        // Nếu client cố gắng đẩy thẳng creationStatus = ACTIVE/COMPLETED nhưng
        // chưa hoàn tất đủ 5 bước thì ép về DRAFT để chi nhánh KHÔNG bị
        // "tung ra ngoài" (hiện trên chợ trọ / tính vào thống kê) khi chưa cấu hình xong.
        boolean allStepsDone = Boolean.TRUE.equals(branch.getStep1Done())
                && Boolean.TRUE.equals(branch.getStep2Done())
                && Boolean.TRUE.equals(branch.getStep3Done())
                && Boolean.TRUE.equals(branch.getStep4Done())
                && Boolean.TRUE.equals(branch.getStep5Done());
        if (!allStepsDone) {
            branch.setCreationStatus("DRAFT");
        } else if (branch.getCreationStatus() == null) {
            branch.setCreationStatus("COMPLETED");
        }

        if (branch.getElectricityPrice() == null) {
            branch.setElectricityPrice(3500.0);
        }
        if (branch.getWaterPrice() == null) {
            branch.setWaterPrice(30000.0);
        }

        return ResponseEntity.status(org.springframework.http.HttpStatus.CREATED)
                .body(ApiResponse.<Branch>builder()
                        .success(true)
                        .message("Tạo chi nhánh thành công!")
                        .data(branchService.create(branch))
                        .build());
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Branch>> update(
            @PathVariable Long id,
            @RequestBody Branch branch,
            Authentication auth) {

        Branch existing = branchRepository.findById(id)
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));

        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        Long ownerId = userId;
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (assignments.stream().noneMatch(a -> a.getBranchId().equals(id))) {
                throw new org.springframework.security.access.AccessDeniedException("Bạn không được phân công quản lý chi nhánh này");
            }
            ownerId = existing.getOwnerId();
        }

        if (!existing.getOwnerId().equals(ownerId)) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền cập nhật chi nhánh này");
        }

        return ResponseEntity.ok(
                ApiResponse.<Branch>builder()
                        .success(true)
                        .message("Cập nhật chi nhánh thành công!")
                        .data(branchService.update(id, branch))
                        .build()
        );
    }

    @PutMapping("/{id}/complete")
    public ResponseEntity<ApiResponse<Branch>> complete(
            @PathVariable Long id,
            Authentication auth) {

        Branch existing = branchRepository.findById(id)
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));

        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        
        Long ownerId = userId;
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (assignments.stream().noneMatch(a -> a.getBranchId().equals(id))) {
                throw new org.springframework.security.access.AccessDeniedException("Bạn không được phân công quản lý chi nhánh này");
            }
            ownerId = existing.getOwnerId();
        }

        if (!existing.getOwnerId().equals(ownerId)) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền hoàn tất chi nhánh này");
        }

        return ResponseEntity.ok(
                ApiResponse.<Branch>builder()
                        .success(true)
                        .message("Hoàn tất tạo dãy trọ thành công!")
                        .data(branchService.complete(id))
                        .build()
        );
    }

    // ═══════════════════════════════════════════════════════════════
    //  QUẢN LÝ CHI NHÁNH — Wizard 4 bước
    // ═══════════════════════════════════════════════════════════════

    /**
     * Tạo chi nhánh ở trạng thái NHÁP (DRAFT) cho wizard 4 bước.
     *
     * Khác với {@code POST /v1/branches} (API cũ, dùng cho luồng tạo nhanh),
     * endpoint này LUÔN ép {@code creationStatus = 'DRAFT'} và reset toàn bộ
     * cờ bước về false. Nhờ đó chi nhánh chưa cấu hình xong sẽ KHÔNG xuất hiện
     * trên chợ trọ và KHÔNG bị tính vào thống kê.
     *
     * Chi nhánh chỉ chuyển sang COMPLETED khi cả 4 bước được đánh dấu hoàn tất
     * qua {@code PUT /v1/branches/{id}/steps/{step}}.
     */
    @PostMapping("/wizard-draft")
    public ResponseEntity<ApiResponse<Branch>> createWizardDraft(
            @RequestBody Branch branch,
            Authentication auth) {

        Long userId = (Long) auth.getPrincipal();
        Long ownerId = userId;
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));

        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (assignments.isEmpty()) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn chưa được phân công làm nhân viên của chủ nhà nào.");
            }
            ownerId = assignments.get(0).getOwnerId();
            boolean isManager = assignments.stream().anyMatch(a -> "MANAGER".equals(a.getStaffRole()));
            branch.setApprovalStatus(isManager ? "APPROVED" : "PENDING_APPROVAL");
        }

        // Kiểm tra giới hạn số chi nhánh của gói cước.
        // Chỉ tính các chi nhánh CHƯA tạm ngừng — chi nhánh đã ngừng hoạt động
        // không còn chiếm quota nên chủ trọ vẫn tạo được chi nhánh mới.
        long currentBranchCount = branchRepository.countActiveQuotaBranchesByOwnerId(ownerId);
        com.stayhub.api.entity.SaasPlan currentPlan = saasService.getCurrentPlan(ownerId);
        if (currentPlan != null && currentPlan.getMaxBranches() != null
                && currentBranchCount >= currentPlan.getMaxBranches()) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.BAD_REQUEST,
                "Bạn đã đạt giới hạn tối đa " + currentPlan.getMaxBranches() + " chi nhánh của gói " + currentPlan.getName() + ". Vui lòng nâng cấp gói cước để tạo thêm.");
        }

        branch.setOwnerId(ownerId);

        // ── Ép trạng thái nháp & reset tiến độ wizard ──
        branch.setCreationStatus("DRAFT");
        branch.setStep1Done(false);
        branch.setStep2Done(false);
        branch.setStep3Done(false);
        branch.setStep4Done(false);
        branch.setStep5Done(false);
        branch.setCompletedAt(null);

        if (branch.getElectricityPrice() == null) {
            branch.setElectricityPrice(3500.0);
        }
        if (branch.getWaterPrice() == null) {
            branch.setWaterPrice(30000.0);
        }

        return ResponseEntity.status(org.springframework.http.HttpStatus.CREATED)
                .body(ApiResponse.<Branch>builder()
                        .success(true)
                        .message("Đã tạo chi nhánh nháp. Hãy hoàn tất 4 bước cấu hình.")
                        .data(branchService.create(branch))
                        .build());
    }

    /**
     * Lấy TẤT CẢ chi nhánh của chủ nhà (mọi trạng thái) để màn hình
     * "Quản lý chi nhánh" nhóm theo: đang hoạt động / đang khởi tạo / ngừng hoạt động.
     */
    @GetMapping("/owner/{ownerId}/management")
    public ResponseEntity<ApiResponse<List<Branch>>> getAllForManagement(
            @PathVariable Long ownerId,
            Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        Long effectiveOwnerId = ownerId;
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (assignments.isEmpty()) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn chưa được phân công làm nhân viên của chủ nhà nào.");
            }
            effectiveOwnerId = assignments.get(0).getOwnerId();
        } else if (!userId.equals(ownerId)) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền xem chi nhánh của chủ nhà khác");
        }
        return ResponseEntity.ok(ApiResponse.<List<Branch>>builder()
                .success(true)
                .message("Lấy danh sách chi nhánh thành công!")
                .data(branchService.getAllByOwnerForManagement(effectiveOwnerId))
                .build());
    }

    /**
     * Đánh dấu hoàn tất / bỏ hoàn tất 1 bước trong wizard 4 bước.
     * Khi cả 4 bước đều true → tự động chuyển creationStatus sang COMPLETED.
     */
    @PutMapping("/{id}/steps/{step}")
    public ResponseEntity<ApiResponse<Branch>> markStep(
            @PathVariable Long id,
            @PathVariable int step,
            @RequestParam(name = "done", defaultValue = "true") boolean done,
            Authentication auth) {
        Branch existing = branchRepository.findById(id)
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));
        assertBranchAccess(existing, auth, "cập nhật tiến độ chi nhánh này");
        return ResponseEntity.ok(ApiResponse.<Branch>builder()
                .success(true)
                .message("Cập nhật tiến độ bước " + step + " thành công!")
                .data(branchService.markStep(id, step, done))
                .build());
    }

    /**
     * Tạm ngừng hoạt động chi nhánh (SUSPENDED) — giữ dữ liệu, ẩn khỏi chợ trọ.
     */
    @PutMapping("/{id}/suspend")
    public ResponseEntity<ApiResponse<Branch>> suspend(
            @PathVariable Long id,
            Authentication auth) {
        Branch existing = branchRepository.findById(id)
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));
        assertBranchAccess(existing, auth, "tạm ngừng chi nhánh này");
        return ResponseEntity.ok(ApiResponse.<Branch>builder()
                .success(true)
                .message("Đã tạm ngừng hoạt động chi nhánh!")
                .data(branchService.suspend(id))
                .build());
    }

    /**
     * Kích hoạt lại chi nhánh đã tạm ngừng (SUSPENDED → COMPLETED).
     */
    @PutMapping("/{id}/resume")
    public ResponseEntity<ApiResponse<Branch>> resume(
            @PathVariable Long id,
            Authentication auth) {
        Branch existing = branchRepository.findById(id)
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));
        assertBranchAccess(existing, auth, "kích hoạt lại chi nhánh này");
        return ResponseEntity.ok(ApiResponse.<Branch>builder()
                .success(true)
                .message("Đã kích hoạt lại chi nhánh!")
                .data(branchService.resume(id))
                .build());
    }

    /**
     * Kiểm tra quyền truy cập chi nhánh: chủ sở hữu hoặc nhân viên được phân công.
     */
    private void assertBranchAccess(Branch branch, Authentication auth, String action) {
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = staffService.getAssignments(userId);
            if (assignments.stream().noneMatch(a -> a.getBranchId() != null && a.getBranchId().equals(branch.getId()))) {
                throw new org.springframework.security.access.AccessDeniedException("Bạn không được phân công quản lý chi nhánh này");
            }
            return;
        }
        if (!branch.getOwnerId().equals(userId)) {
            throw new org.springframework.security.access.AccessDeniedException("Bạn không có quyền " + action);
        }
    }
}
