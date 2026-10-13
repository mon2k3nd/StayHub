package com.stayhub.api.service.impl;

import com.stayhub.api.dto.response.NearbyBranchDto;
import com.stayhub.api.entity.Branch;
import com.stayhub.api.entity.Notification;
import com.stayhub.api.entity.NotificationScope;
import com.stayhub.api.entity.NotificationType;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.BranchRepository;
import com.stayhub.api.repository.NotificationRepository;
import com.stayhub.api.service.BranchService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.time.LocalDateTime;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@lombok.extern.slf4j.Slf4j
public class BranchServiceImpl implements BranchService {

    private final BranchRepository branchRepository;
    private final com.stayhub.api.repository.RoomRepository roomRepository;
    private final com.stayhub.api.service.BranchGroupChatService branchGroupChatService;
    private final com.stayhub.api.service.CloudStorageService cloudStorageService;
    private final com.stayhub.api.repository.SharedFacilityRepository sharedFacilityRepository;

    @jakarta.persistence.PersistenceContext
    private jakarta.persistence.EntityManager entityManager;
    private final com.stayhub.api.repository.ComplaintRepository complaintRepository;
    private final com.fasterxml.jackson.databind.ObjectMapper objectMapper;
    private final NotificationRepository notificationRepository;
    private final com.stayhub.api.service.SaasService saasService;
    private final com.stayhub.api.repository.RoomPostRepository roomPostRepository;
    private final com.stayhub.api.repository.VoucherRepository voucherRepository;
    private final com.stayhub.api.repository.CashSessionRepository cashSessionRepository;

    @Override
    public List<Branch> getByOwner(Long ownerId) {
        List<Branch> branches = branchRepository.findByOwnerIdAndIsActiveTrue(ownerId);
        // Lﻕﭨc bﻕﭨ DRAFT (vﺣ؛ DRAFT cﺣﺏ API riﺣ۹ng getDraftsByOwner)
        branches = branches.stream()
                .filter(b -> !"DRAFT".equals(b.getCreationStatus()))
                .collect(java.util.stream.Collectors.toList());
        if (!branches.isEmpty()) {
            List<Long> branchIds = branches.stream().map(Branch::getId).collect(java.util.stream.Collectors.toList());
            List<Object[]> counts = roomRepository.countRoomsByBranchIdIn(branchIds);
            java.util.Map<Long, Integer> countMap = new java.util.HashMap<>();
            for (Object[] row : counts) {
                countMap.put(((Number) row[0]).longValue(), ((Number) row[1]).intValue());
            }
            for (Branch branch : branches) {
                branch.setTotalRooms(countMap.getOrDefault(branch.getId(), 0));
            }
        }
        return branches;
    }

    @Override
    public List<Branch> getDeletedByOwner(Long ownerId) {
        List<Branch> branches = branchRepository.findByOwnerIdAndIsActiveFalse(ownerId);
        if (!branches.isEmpty()) {
            List<Long> branchIds = branches.stream().map(Branch::getId).collect(java.util.stream.Collectors.toList());
            List<Object[]> counts = roomRepository.countRoomsByBranchIdIn(branchIds);
            java.util.Map<Long, Integer> countMap = new java.util.HashMap<>();
            for (Object[] row : counts) {
                countMap.put(((Number) row[0]).longValue(), ((Number) row[1]).intValue());
            }
            for (Branch branch : branches) {
                branch.setTotalRooms(countMap.getOrDefault(branch.getId(), 0));
            }
        }
        return branches;
    }

    @Override
    public List<Branch> getDraftsByOwner(Long ownerId) {
        List<Branch> branches = branchRepository.findByOwnerIdAndIsActiveTrueAndCreationStatus(ownerId, "DRAFT");
        if (!branches.isEmpty()) {
            List<Long> branchIds = branches.stream().map(Branch::getId).collect(java.util.stream.Collectors.toList());
            List<Object[]> counts = roomRepository.countRoomsByBranchIdIn(branchIds);
            java.util.Map<Long, Integer> countMap = new java.util.HashMap<>();
            for (Object[] row : counts) {
                countMap.put(((Number) row[0]).longValue(), ((Number) row[1]).intValue());
            }
            for (Branch branch : branches) {
                branch.setTotalRooms(countMap.getOrDefault(branch.getId(), 0));
            }
        }
        return branches;
    }

    @Override
    public boolean isBranchCodeTaken(String code, Long excludeId) {
        // Chﻕﭨ kiﻕﭨm tra trong cﺣ۰c branch ﺥang active (is_active = true)
        // Bﻕﭨ qua branch bﻕﭨ xﺣﺏa mﻕﭨm (is_active = false)
        if (code == null || code.trim().isEmpty()) {
            return false;
        }
        // QUAN TRONG: phai tinh CA branch da xoa mem.
        // Cot branch_code co UNIQUE INDEX o tang DB, nen ma cua branch da xoa
        // van chiem cho. Neu chi kiem tra branch "nhin thay duoc" thi se bao
        // "chua trung" nhung luc INSERT lai vi pham unique index.
        return branchRepository.existsByBranchCodeIncludingDeleted(code.trim(), excludeId);
    }

    @Override
    public Branch findConflictingBranch(String code, Long excludeId) {
        if (code == null || code.trim().isEmpty()) {
            return null;
        }
        return branchRepository.findConflictingByBranchCode(code.trim(), excludeId).orElse(null);
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public Branch create(Branch branch) {
        if (branch.getBranchCode() == null || branch.getBranchCode().trim().isEmpty()) {
            throw new IllegalArgumentException("Mﺣ۲ dﺣ۲y trﻕﭨ (branchCode) lﺣ  bﻕﭦﺁt buﻕﭨc.");
        }
        
        // Kiem tra trung ma BAO GOM ca branch da xoa mem (unique index o DB).
        if (branchRepository.existsByBranchCodeIncludingDeleted(branch.getBranchCode().trim(), null)) {
            throw new IllegalArgumentException("Mã dãy trọ đã tồn tại. Vui lòng chọn mã khác.");
        }

        // Apply Dual Address System (2026) mapping
        if (branch.getAddressOld() != null && !branch.getAddressOld().isEmpty()) {
            com.stayhub.api.service.AddressMapper.Address3Tier mapped = com.stayhub.api.service.AddressMapper.mapTo3Tier(branch.getAddressOld());
            branch.setLegalProvince(mapped.getProvince());
            branch.setLegalWard(mapped.getWard());
            branch.setLegalDistrict(""); // Omit district as per new rule
        }

        // Process coverImages base64 to URLs
        if (branch.getCoverImages() != null && branch.getCoverImages().startsWith("[")) {
            try {
                java.util.List<String> b64List = objectMapper.readValue(branch.getCoverImages(), new com.fasterxml.jackson.core.type.TypeReference<java.util.List<String>>() {});
                java.util.List<String> urls = new java.util.ArrayList<>();
                for (String b64 : b64List) {
                    String url = cloudStorageService.uploadBase64(b64);
                    if (url != null) urls.add(url);
                }
                branch.setCoverImages(objectMapper.writeValueAsString(urls));
                if (!urls.isEmpty()) {
                    branch.setCoverImage(urls.get(0));
                }
            } catch (Exception e) {
                throw new RuntimeException("Lﻕﭨi xﻕﭨ­ lﺣﺛ ﻕﭦ۲nh: " + e.getMessage());
            }
        }
        
        // Process pcccImages base64 to URLs
        if (branch.getPcccImages() != null && branch.getPcccImages().startsWith("[")) {
            try {
                java.util.List<String> b64List = objectMapper.readValue(branch.getPcccImages(), new com.fasterxml.jackson.core.type.TypeReference<java.util.List<String>>() {});
                java.util.List<String> urls = new java.util.ArrayList<>();
                for (String b64 : b64List) {
                    if (b64.startsWith("http")) {
                        urls.add(b64);
                    } else {
                        String url = cloudStorageService.uploadBase64(b64);
                        if (url != null) urls.add(url);
                    }
                }
                branch.setPcccImages(objectMapper.writeValueAsString(urls));
            } catch (Exception e) {
                throw new RuntimeException("Lﻕﭨi xﻕﭨ­ lﺣﺛ ﻕﭦ۲nh PCCC: " + e.getMessage());
            }
        }

        
        Branch saved = branchRepository.save(branch);
        java.util.List<com.stayhub.api.entity.Room> rooms = new java.util.ArrayList<>();
        // Khai báo ở scope method để dùng được sau khi rooms đã persist (linkFacilitiesOwningSide).
        java.util.Map<String, com.stayhub.api.entity.SharedFacility> wcMap = new java.util.HashMap<>();

        try {
            // Check if description contains advancedMeta JSON
            // (floors = bước 3, sharedAssets = bước 2 — xử lý độc lập)
            if (branch.getDescription() != null
                    && (branch.getDescription().contains("\"floors\"")
                        || branch.getDescription().contains("\"sharedAssets\"")
                        || branch.getDescription().contains("\"branchAmenities\""))) {
                com.fasterxml.jackson.databind.JsonNode meta = objectMapper.readTree(branch.getDescription());

                // 0. Process Branch Amenities → map giá tiện ích (Wifi/Gửi xe/Rác…)
                //    sang các cột phí của chi nhánh. Frontend gửi giá thật trong
                //    `branchAmenities`; nếu bỏ qua bước này thì các cột
                //    internet_fee/parking_fee/garbage_fee sẽ giữ 0 ⇒ hiển thị
                //    "Miễn phí" ở chi tiết phòng dù chủ nhà đã nhập giá.
                applyAmenityFees(saved, meta);

                // 1. Process Shared WCs
                if (meta.has("sharedWcs")) {
                    for (com.fasterxml.jackson.databind.JsonNode wcNode : meta.get("sharedWcs")) {
                        // Mã WC (tempId/code) lưu vào notes để Smart Sync nhận diện lại.
                        String wcTempId = wcNode.has("tempId") ? wcNode.get("tempId").asText()
                            : (wcNode.has("code") ? wcNode.get("code").asText() : null);
                        com.stayhub.api.entity.SharedFacility facility = com.stayhub.api.entity.SharedFacility.builder()
                            .branchId(saved.getId())
                            .name(wcNode.get("name").asText())
                            .type("WC")
                            .notes(wcTempId)
                            .build();
                        facility = sharedFacilityRepository.save(facility);
                        if (wcTempId != null) wcMap.put(wcTempId, facility);
                    }
                }

                // 1b. Process Shared Assets (tài sản chung: máy giặt, tủ lạnh, ...)
                if (meta.has("sharedAssets")) {
                    for (com.fasterxml.jackson.databind.JsonNode assetNode : meta.get("sharedAssets")) {
                        String assetName = assetNode.has("name") ? assetNode.get("name").asText() : "";
                        if (assetName == null || assetName.trim().isEmpty()) continue;
                        com.stayhub.api.entity.SharedFacility asset = com.stayhub.api.entity.SharedFacility.builder()
                            .branchId(saved.getId())
                            .name(assetName)
                            .type("ASSET")
                            .notes(assetNode.has("note") ? assetNode.get("note").asText() : null)
                            .images(assetNode.has("images") ? assetNode.get("images").toString() : null)
                            .equipment(assetNode.has("quantity") ? assetNode.get("quantity").asText() : "1")
                            .build();
                        sharedFacilityRepository.save(asset);
                    }
                }

                // 2. Process Floors and Rooms
                if (meta.has("floors")) {
                    for (com.fasterxml.jackson.databind.JsonNode fNode : meta.get("floors")) {
                        int fNum = fNode.get("floorNumber").asInt();
                        if (fNode.has("rooms")) {
                            for (com.fasterxml.jackson.databind.JsonNode rNode : fNode.get("rooms")) {
                                // Tên phòng ngắn (VD: P101). roomCode PHẢI duy nhất toàn hệ
                                // thống nên luôn ghép tiền tố branchCode — không nhận code
                                // thô từ client để tránh trùng giữa các chi nhánh.
                                boolean isSelfContained = rNode.has("isSelfContained") && rNode.get("isSelfContained").asBoolean();
                                String wcId = rNode.has("sharedWcId") && !rNode.get("sharedWcId").isNull() ? rNode.get("sharedWcId").asText() : null;

                                // Cấu hình chi tiết phòng do RoomConfigBottomSheet sinh ra
                                // được wizard lưu LỒNG trong `detailedInfo` (xem
                                // _RoomDraft.toJson của step3_spatial_structure_widget).
                                // Trước đây backend chỉ đọc price/area ở node gốc ⇒ luôn
                                // nhận 0 và bỏ qua toàn bộ detailedInfo ⇒ sang màn
                                // "Xem trước" chi tiết phòng trống trơn / sai dữ liệu.
                                com.fasterxml.jackson.databind.JsonNode rInfoNode =
                                    rNode.has("detailedInfo") && rNode.get("detailedInfo").isObject()
                                        ? rNode.get("detailedInfo") : null;

                                // Tên phòng: ưu tiên tên chủ nhà nhập trong
                                // RoomConfigBottomSheet (`detailedInfo.roomName`), rồi
                                // mới tới `code`/`tempId` của sơ đồ. Trước đây chỉ lấy
                                // tempId nên tên phòng người dùng đặt bị mất.
                                String rName = null;
                                if (rInfoNode != null && rInfoNode.has("roomName")
                                        && !rInfoNode.get("roomName").asText().isBlank()) {
                                    rName = rInfoNode.get("roomName").asText().trim();
                                }
                                if (rName == null || rName.isEmpty()) {
                                    rName = rNode.has("code") ? rNode.get("code").asText()
                                        : (rNode.has("tempId") ? rNode.get("tempId").asText() : "");
                                }

                                Double rPrice = rNode.has("price") ? rNode.get("price").asDouble()
                                    : (rInfoNode != null && rInfoNode.has("price") ? rInfoNode.get("price").asDouble() : 0.0);
                                Double rArea = rNode.has("area") ? rNode.get("area").asDouble()
                                    : (rInfoNode != null && rInfoNode.has("area") ? rInfoNode.get("area").asDouble() : 0.0);
                                Double rDeposit = rNode.has("deposit") ? rNode.get("deposit").asDouble()
                                    : (rInfoNode != null && rInfoNode.has("deposit") ? rInfoNode.get("deposit").asDouble() : 0.0);
                                
                                // roomCode PHẢI duy nhất toàn hệ thống. Nếu chi nhánh cũ
                                // từng ở cùng địa chỉ đã bị tạm ngừng nhưng room_code CHƯA
                                // được gắn hậu tố `_OFF_<id>` (dữ liệu cũ trước khi vá), thì
                                // mã sinh ra ở đây sẽ trùng với dòng cũ ⇒ INSERT ném
                                // "duplicate key value violates unique constraint".
                                // Trong trường hợp đó, thêm hậu tố phân biệt theo id chi
                                // nhánh mới để không đụng dòng của chi nhánh khác.
                                String desiredCode = saved.getBranchCode() + "_" + rName;
                                java.util.Optional<com.stayhub.api.entity.Room> clash =
                                    roomRepository.findByRoomCodeIncludingDeleted(desiredCode);
                                if (clash.isPresent()
                                        && clash.get().getBranchId() != null
                                        && !clash.get().getBranchId().equals(saved.getId())) {
                                    desiredCode = desiredCode + "_B" + saved.getId();
                                }

                                // ── Suy ra các trường entity từ detailedInfo của wizard ──
                                Integer rMaxGuests = rInfoNode != null && rInfoNode.has("maxOccupants")
                                        ? rInfoNode.get("maxOccupants").asInt() : null;
                                Integer rMaxVehicles = rInfoNode != null && rInfoNode.has("maxVehicles")
                                        ? rInfoNode.get("maxVehicles").asInt() : null;
                                Double rMezzanineArea = rInfoNode != null && rInfoNode.has("mezzanineArea")
                                        ? rInfoNode.get("mezzanineArea").asDouble() : null;
                                // Chuẩn hoá về MÃ canonical (vd PHONG_THUONG → PHONG_TRO)
                                // để cột `room_sub_type` luôn là id-mô-hình, không phải nhãn.
                                String rRoomSubType = null;
                                if (rInfoNode != null && rInfoNode.has("roomType")
                                        && !rInfoNode.get("roomType").isNull()) {
                                    rRoomSubType = com.stayhub.api.util.RoomTypeCodes.toCode(
                                            rInfoNode.get("roomType").asText());
                                }
                                String rDirection = rInfoNode != null && rInfoNode.has("orientation")
                                        ? rInfoNode.get("orientation").asText() : null;
                                Boolean rHasBalcony = rInfoNode != null && rInfoNode.has("hasBalcony")
                                        ? rInfoNode.get("hasBalcony").asBoolean() : null;
                                Boolean rHasWindow = rInfoNode != null && rInfoNode.has("hasWindow")
                                        ? rInfoNode.get("hasWindow").asBoolean() : null;
                                // Danh sách nội thất (mã) → JSON array cho cột `furniture`.
                                String rFurniture = null;
                                if (rInfoNode != null && rInfoNode.has("furnitureItems")
                                        && rInfoNode.get("furnitureItems").isArray()) {
                                    rFurniture = rInfoNode.get("furnitureItems").toString();
                                }
                                // Ảnh phòng chính (đã upload Cloudinary ở bước cấu hình).
                                String rRoomImages = null;
                                if (rInfoNode != null && rInfoNode.has("photos")
                                        && rInfoNode.get("photos").isArray()) {
                                    rRoomImages = rInfoNode.get("photos").toString();
                                }

                                com.stayhub.api.entity.Room r = com.stayhub.api.entity.Room.builder()
                                        .ownerId(saved.getOwnerId())
                                        .branchId(saved.getId())
                                        .roomName(rName)
                                        .floor(fNum)
                                        .roomCode(desiredCode)
                                        .address(branch.getAddress())
                                        .addressOld(branch.getAddressOld())
                                        .status(com.stayhub.api.entity.RoomStatus.KHOA_CHO_CAP_NHAT)
                                        .price(rPrice)
                                        .floorArea(rArea)
                                        .deposit(rDeposit)
                                        .baseDeposit(rDeposit)
                                        .maxGuests(rMaxGuests)
                                        .maxVehicles(rMaxVehicles)
                                        .mezzanineArea(rMezzanineArea)
                                        .roomSubType(rRoomSubType)
                                        .direction(rDirection)
                                        .hasBalcony(rHasBalcony)
                                        .hasWindow(rHasWindow)
                                        .furniture(rFurniture)
                                        .roomImages(rRoomImages)
                                        .bathroomType(isSelfContained ? "RIENG" : "CHUNG")
                                        .isSharedWc(!isSelfContained)
                                        .sharedWcId(wcId)
                                        .electricityPrice(branch.getElectricityPrice())
                                        .waterPrice(branch.getWaterPrice())
                                        .serviceFee(branch.getServiceFee())
                                        .electricityPricingType(branch.getElectricityPricingType())
                                        .waterPricingType(branch.getWaterPricingType())
                                        .serviceFeePricingType(branch.getServiceFeePricingType())
                                        .sharedFacilities(new java.util.ArrayList<>())
                                        .build();

                                // Lﺩﺍu isSelfContained vﺣ  pricing type vﺣ o detailedInfo ﺥﻕﭨ config screen ﺥﻕﭨc lﻕﭦ۰i
                                java.util.Map<String, Object> rInfo = new java.util.HashMap<>();
                                // Merge TOÀN BỘ cấu hình chi tiết do RoomConfigBottomSheet
                                // sinh ra (roomType, featurePhotos, furnitureItems,
                                // orientation, waterPerPersonPrice, electricIndex…) để màn
                                // "Xem trước" chi tiết phòng hiển thị đầy đủ, đúng dữ liệu.
                                if (rInfoNode != null) {
                                    try {
                                        @SuppressWarnings("unchecked")
                                        java.util.Map<String, Object> parsed =
                                            objectMapper.convertValue(rInfoNode, java.util.Map.class);
                                        if (parsed != null) rInfo.putAll(parsed);
                                    } catch (Exception ignore) {
                                        // Bỏ qua nếu không convert được — vẫn giữ field cơ bản.
                                    }
                                }
                                rInfo.put("isSelfContained", isSelfContained);
                                if (branch.getWaterPricingType() != null) {
                                    rInfo.put("waterPricingType", branch.getWaterPricingType().name());
                                }
                                r.setDetailedInfo(rInfo);

                                // Lưu ý: Room.sharedFacilities là phía INVERSE (mappedBy="rooms")
                                // nên thêm vào đây KHÔNG được Hibernate persist. Phải gán ở phía
                                // OWNING (SharedFacility.rooms) — xem bước linkFacilitiesOwningSide()
                                // sau khi rooms đã có ID.
                                if (!isSelfContained && wcId != null && wcMap.containsKey(wcId)) {
                                    r.getSharedFacilities().add(wcMap.get(wcId));
                                }
                                rooms.add(r);
                            }
                        }
                    }
                }
                
                // GIỮ LẠI JSON mô tả cấu trúc (floors/sharedWcs/sharedAssets/
                // branchAmenities/customAmenities…). Trước đây chỗ này xoá trắng
                // description, khiến giá tiện ích (Wifi/Gửi xe/Rác) và cấu trúc
                // tầng/phòng biến mất sau khi tạo ⇒ mở lại chi nhánh để sửa thì
                // các ô giá trống và chi tiết phòng hiển thị "Miễn phí".
                // Nhánh UPDATE đã giữ JSON (xem setDescription(incomingDescription)),
                // nên nhánh CREATE phải đối xứng để dữ liệu không bị mất.
                saved.setDescription(branch.getDescription());
                branchRepository.save(saved);

            } else {
                // Fallback to basic generation
                java.util.List<Integer> perFloorList = branch.getRoomsPerFloorList();
                boolean hasPerFloorList = perFloorList != null && !perFloorList.isEmpty();
                int numFloors = branch.getNumberOfFloors() != null ? branch.getNumberOfFloors() : (hasPerFloorList ? perFloorList.size() : 0);

                if (hasPerFloorList || (branch.getNumberOfFloors() != null && branch.getRoomsPerFloor() != null)) {
                    for (int f = 1; f <= numFloors; f++) {
                        int roomsThisFloor = hasPerFloorList && f <= perFloorList.size()
                            ? perFloorList.get(f - 1)
                            : (branch.getRoomsPerFloor() != null ? branch.getRoomsPerFloor() : 1);
                        for (int r = 1; r <= roomsThisFloor; r++) {
                            String rName = String.format("%d%02d", f, r);
                            rooms.add(com.stayhub.api.entity.Room.builder()
                                    .ownerId(saved.getOwnerId())
                                    .branchId(saved.getId())
                                    .roomName(rName)
                                    .floor(f)
                                    .roomCode(saved.getBranchCode() + "_" + rName)
                                    .status(com.stayhub.api.entity.RoomStatus.KHOA_CHO_CAP_NHAT)
                                    .price(0.0)
                                    .electricityPrice(branch.getElectricityPrice())
                                    .waterPrice(branch.getWaterPrice())
                                    .serviceFee(branch.getServiceFee())
                                    .electricityPricingType(branch.getElectricityPricingType())
                                    .waterPricingType(branch.getWaterPricingType())
                                    .serviceFeePricingType(branch.getServiceFeePricingType())
                                    .build());
                        }
                    }
                } else if (saved.getTotalRooms() != null && saved.getTotalRooms() > 0) {
                    for (int i = 1; i <= saved.getTotalRooms(); i++) {
                        String rName = "Phﺣﺎng " + i;
                        rooms.add(com.stayhub.api.entity.Room.builder()
                                .ownerId(saved.getOwnerId())
                                .branchId(saved.getId())
                                .roomName(rName)
                                .roomCode(saved.getBranchCode() + "_" + rName.replace(" ", ""))
                                .status(com.stayhub.api.entity.RoomStatus.KHOA_CHO_CAP_NHAT)
                                .price(0.0)
                                .electricityPrice(branch.getElectricityPrice())
                                .waterPrice(branch.getWaterPrice())
                                .serviceFee(branch.getServiceFee())
                                .electricityPricingType(branch.getElectricityPricingType())
                                .waterPricingType(branch.getWaterPricingType())
                                .serviceFeePricingType(branch.getServiceFeePricingType())
                                .build());
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            // Ignore JSON parse error and proceed with basic gen if needed
        }

        // ﻗﻗ Secondary fallback: if floors parsed but produced 0 rooms, use totalRooms ﻗﻗ
        if (rooms.isEmpty() && saved.getTotalRooms() != null && saved.getTotalRooms() > 0) {
            for (int i = 1; i <= saved.getTotalRooms(); i++) {
                String rName = "Phﺣﺎng " + i;
                rooms.add(com.stayhub.api.entity.Room.builder()
                        .ownerId(saved.getOwnerId())
                        .branchId(saved.getId())
                        .roomName(rName)
                        .roomCode(saved.getBranchCode() + "_" + rName.replace(" ", ""))
                        .status(com.stayhub.api.entity.RoomStatus.KHOA_CHO_CAP_NHAT)
                        .price(0.0)
                        .electricityPrice(branch.getElectricityPrice())
                        .waterPrice(branch.getWaterPrice())
                        .serviceFee(branch.getServiceFee())
                        .electricityPricingType(branch.getElectricityPricingType())
                        .waterPricingType(branch.getWaterPricingType())
                        .serviceFeePricingType(branch.getServiceFeePricingType())
                        .build());
            }
        }

        if (!rooms.isEmpty()) {
            long currentRoomCount = roomRepository.countByOwnerId(saved.getOwnerId());
            com.stayhub.api.entity.SaasPlan currentPlan = saasService.getCurrentPlan(saved.getOwnerId());
            if (currentRoomCount + rooms.size() > currentPlan.getMaxRooms()) {
                throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.BAD_REQUEST, 
                    "Bﻕﭦ۰n ﺥﺣ۲ ﺥﻕﭦ۰t giﻕﭨi hﻕﭦ۰n tﻕﭨi ﺥa " + currentPlan.getMaxRooms() + " phﺣﺎng cﻕﭨ۶a gﺣﺏi " + currentPlan.getName() + ". Vui lﺣﺎng nﺣ۱ng cﻕﭦ۴p gﺣﺏi cﺩﺍﻕﭨc ﺥﻕﭨ tﻕﭦ۰o thﺣ۹m.");
            }

            roomRepository.saveAll(rooms);
            saved.setTotalRooms(rooms.size());
            branchRepository.save(saved);

            // Persist quan hệ phòng ↔ WC ở phía OWNING (SharedFacility.rooms).
            // Bắt buộc vì Room.sharedFacilities là phía inverse (mappedBy) —
            // thêm vào đó không tạo bản ghi trong bảng nối room_shared_facilities.
            // Phải chạy SAU saveAll để rooms đã có ID.
            linkFacilitiesOwningSide(wcMap.values(), rooms);
        }

        // ﻭ Gﻕﭨ­i thﺣﺑng bﺣ۰o cho chﻕﭨ۶ nhﺣ : Chi nhﺣ۰nh tﻕﭦ۰o thﺣ nh cﺣﺑng, vﺣ o cﻕﭦ۴u hﺣ؛nh chi tiﻕﭦﺟt
        try {
            String meta = objectMapper.writeValueAsString(java.util.Map.of(
                "action", "NAVIGATE",
                "screen", "BRANCH_DETAIL_CONFIG",
                "branchId", saved.getId(),
                "branchName", saved.getBranchName()
            ));
                String roomNamesText = "";
                if (!rooms.isEmpty()) {
                    String names = rooms.stream().map(com.stayhub.api.entity.Room::getRoomName).limit(5).collect(java.util.stream.Collectors.joining(", "));
                    if (rooms.size() > 5) names += "...";
                    roomNamesText = " (" + names + ")";
                }
                Notification notif = Notification.builder()
                .receiverId(saved.getOwnerId())
                .title("ﻭ Tﻕﭦ۰o chi nhﺣ۰nh thﺣ nh cﺣﺑng!")
                .content("Chi nhﺣ۰nh \"" + saved.getBranchName() + "\" ﺥﺣ۲ ﺥﺩﺍﻕﭨ۲c tﻕﭦ۰o vﻕﭨi " + saved.getTotalRooms() + " phﺣﺎng" + roomNamesText + ". Bﻕﭦ۴m vﺣ o ﺥﺣ۱y ﺥﻕﭨ cﻕﭦ۴u hﺣ؛nh chi tiﻕﭦﺟt tﻕﭨ،ng phﺣﺎng.")
                .type(NotificationType.BRANCH_CREATED)
                .scope(NotificationScope.INDIVIDUAL)
                .refId(saved.getId())
                .isActionable(true)
                .actionMetadata(meta)
                .build();
            notificationRepository.save(notif);
        } catch (Exception ignore) { log.warn("Ignored exception in BranchServiceImpl: ", ignore); }

        return saved;

    }

    @Override
    public Branch complete(Long id) {
        Branch existing = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Khﺣﺑng tﺣ؛m thﻕﭦ۴y dﺣ۲y trﻕﭨ ID: " + id));
        existing.setCreationStatus("COMPLETED");
        Branch saved = branchRepository.save(existing);

        // ﻭ Gﻕﭨ­i thﺣﺑng bﺣ۰o: Cﻕﭦ۴u hﺣ؛nh hoﺣ n tﻕﭦ۴t ﻗ gﻕﭨ۲i ﺣﺛ ﺥﺥng bﺣ i cho thuﺣ۹
        try {
            String meta = objectMapper.writeValueAsString(java.util.Map.of(
                "action", "NAVIGATE",
                "screen", "CREATE_POST",
                "branchId", saved.getId(),
                "branchName", saved.getBranchName()
            ));
            Notification notif = Notification.builder()
                .receiverId(saved.getOwnerId())
                .title("ﻗ Cﻕﭦ۴u hﺣ؛nh chi nhﺣ۰nh hoﺣ n tﻕﭦ۴t!")
                .content("Cﺣ۰c phﺣﺎng cﻕﭨ۶a \"" + saved.getBranchName() + "\" ﺥﺣ۲ sﻕﭦﭖn sﺣ ng. Hﺣ۲y ﺥﺥng bﺣ i cho thuﺣ۹ ngay ﺥﻕﭨ tﺣ؛m khﺣ۰ch nhﺣ۸!")
                .type(NotificationType.BRANCH_CONFIG_COMPLETED)
                .scope(NotificationScope.INDIVIDUAL)
                .refId(saved.getId())
                .isActionable(true)
                .actionMetadata(meta)
                .build();
            notificationRepository.save(notif);
        } catch (Exception ignore) { log.warn("Ignored exception in BranchServiceImpl: ", ignore); }

        return saved;
    }

    // ═══════════════════════════════════════════════════════════════
    //  QUẢN LÝ CHI NHÁNH — Wizard 4 bước
    // ═══════════════════════════════════════════════════════════════

    @Override
    public List<Branch> getAllByOwnerForManagement(Long ownerId) {
        // Lấy mọi chi nhánh chưa xoá mềm của chủ nhà (mọi trạng thái vòng đời).
        List<Branch> branches = branchRepository.findByOwnerId(ownerId).stream()
                .filter(b -> b.getIsDeleted() == null || !b.getIsDeleted())
                .collect(Collectors.toList());

        if (!branches.isEmpty()) {
            List<Long> branchIds = branches.stream().map(Branch::getId).collect(Collectors.toList());
            List<Object[]> counts = roomRepository.countRoomsByBranchIdIn(branchIds);
            java.util.Map<Long, Integer> countMap = new java.util.HashMap<>();
            for (Object[] row : counts) {
                countMap.put(((Number) row[0]).longValue(), ((Number) row[1]).intValue());
            }
            for (Branch branch : branches) {
                branch.setTotalRooms(countMap.getOrDefault(branch.getId(), 0));
            }
        }
        return branches;
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public Branch markStep(Long id, int step, boolean done) {
        Branch existing = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));

        switch (step) {
            case 1 -> existing.setStep1Done(done);
            case 2 -> existing.setStep2Done(done);
            case 3 -> existing.setStep3Done(done);
            case 4 -> existing.setStep4Done(done);
            case 5 -> existing.setStep5Done(done);
            default -> throw new IllegalArgumentException("Bước không hợp lệ: " + step + " (chỉ chấp nhận 1..5)");
        }

        boolean allDone = Boolean.TRUE.equals(existing.getStep1Done())
                && Boolean.TRUE.equals(existing.getStep2Done())
                && Boolean.TRUE.equals(existing.getStep3Done())
                && Boolean.TRUE.equals(existing.getStep4Done())
                && Boolean.TRUE.equals(existing.getStep5Done());

        if (allDone) {
            // Đủ 5 bước → chốt hoàn tất, ghi mốc thời gian.
            existing.setCreationStatus("COMPLETED");
            if (existing.getCompletedAt() == null) {
                existing.setCompletedAt(LocalDateTime.now());
            }
        } else if ("COMPLETED".equals(existing.getCreationStatus())) {
            // Bỏ tick 1 bước → quay về trạng thái đang cấu hình.
            existing.setCreationStatus("DRAFT");
            existing.setCompletedAt(null);
        }

        return branchRepository.save(existing);
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public Branch suspend(Long id) {
        Branch existing = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));

        // ── CHỐT CHẶN: không cho tạm ngừng khi còn khách thuê / hợp đồng ──
        // Nếu bỏ qua bước này, phòng đang có hợp đồng sẽ bị đánh dấu DONG_CUA
        // và xoá mềm, khiến hợp đồng trỏ tới phòng "không tồn tại".
        List<com.stayhub.api.entity.Room> rooms = roomRepository.findByBranchId(id);
        boolean hasRentedRoom = rooms.stream().anyMatch(r ->
            r.getStatus() == com.stayhub.api.entity.RoomStatus.DA_THUE ||
            r.getCurrentContractId() != null ||
            r.getCurrentTenantId() != null
        );
        if (hasRentedRoom) {
            throw new IllegalStateException(
                "Không thể tạm ngừng chi nhánh vì vẫn còn khách đang thuê hoặc hợp đồng còn thời hạn. "
                + "Vui lòng thanh lý hợp đồng và trả phòng trước.");
        }

        existing.setCreationStatus("SUSPENDED");
        existing.setIsActive(false);
        existing.setUpdatedAt(java.time.LocalDateTime.now());

        // "Nhả" mã chi nhánh: cột branch_code có UNIQUE INDEX ở DB nên nếu giữ
        // nguyên mã thì chủ trọ không thể tạo lại chi nhánh mới cùng mã.
        // Lưu mã gốc vào suspended_code rồi gắn hậu tố _OFF_<id> vào branch_code
        // để giải phóng mã cho lần tạo sau (đồng bộ với delete()).
        // Hậu tố an toàn: nếu trùng ID với chi nhánh đã OFF trước đó thì thêm số
        // đếm (_OFF_<id>_1, _OFF_<id>_2, ...) để không vi phạm UNIQUE.
        String currentCode = existing.getBranchCode();
        String suffix = resolveUniqueOffSuffix(existing.getId(), currentCode);
        if (currentCode != null && !currentCode.trim().isEmpty()
                && !currentCode.contains("_OFF_") && !currentCode.contains("_DEL_")) {
            if (existing.getSuspendedCode() == null) {
                existing.setSuspendedCode(currentCode);
            }
            existing.setBranchCode(currentCode + suffix);
        }
        Branch saved = branchRepository.save(existing);

        // ── TẮT TẤT CẢ PHÒNG THUỘC CHI NHÁNH ──
        // Trước đây suspend() chỉ đổi trạng thái chi nhánh, KHÔNG đụng tới phòng,
        // nên phòng của chi nhánh đã OFF vẫn hiện "đang hoạt động" và vẫn được
        // tính vào thống kê. Đồng bộ hành vi với delete().
        for (com.stayhub.api.entity.Room room : rooms) {
            room.setStatus(com.stayhub.api.entity.RoomStatus.DONG_CUA);
            room.setIsDeleted(true);
            String roomCode = room.getRoomCode();
            if (roomCode != null && !roomCode.contains("_OFF_") && !roomCode.contains("_DEL_")) {
                // room_code có UNIQUE INDEX riêng -> phải tính hậu tố riêng cho
                // từng phòng để tránh đụng mã phòng cũ khi chi nhánh thứ 2 trùng ID.
                String roomSuffix = resolveUniqueRoomOffSuffix(saved.getId(), roomCode);
                room.setRoomCode(roomCode + roomSuffix);
            }
            // Ẩn bài đăng chợ trọ nếu có
            roomPostRepository.findByRoomId(room.getId()).ifPresent(post -> {
                post.setStatus("HIDDEN");
                roomPostRepository.save(post);
            });
        }
        roomRepository.saveAll(rooms);

        // ── TẮT TẤT CẢ TIỆN ÍCH CHUNG ──
        List<com.stayhub.api.entity.SharedFacility> facilities =
                sharedFacilityRepository.findByBranchId(id);
        for (com.stayhub.api.entity.SharedFacility fac : facilities) {
            fac.setIsDeleted(true);
        }
        sharedFacilityRepository.saveAll(facilities);

        // ── GẮN _OFF VÀO MỌI CODE/ĐỊNH DANH CHUỖI THUỘC CHI NHÁNH ──
        applyOffSuffixToBranchEntities(saved.getId(), suffix);

        return saved;
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public Branch resume(Long id) {
        Branch existing = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));

        // Khôi phục mã gốc đã "nhả" lúc tạm ngừng — nhưng chỉ khi mã đó chưa bị
        // chi nhánh khác chiếm dụng trong thời gian tạm ngừng.
        String originalCode = existing.getSuspendedCode();
        if (originalCode == null || originalCode.trim().isEmpty()) {
            // Chi nhánh bị ngừng qua delete() (không lưu suspended_code): mã gốc
            // chính là branch_code hiện tại sau khi gỡ hậu tố _OFF_<id>.
            originalCode = stripOffSuffix(existing.getBranchCode(), existing.getId());
        }
        if (originalCode != null && !originalCode.trim().isEmpty()) {
            boolean takenByOther = branchRepository
                    .existsByBranchCodeIncludingDeleted(originalCode.trim(), existing.getId());
            if (takenByOther) {
                throw new IllegalArgumentException(
                        "Không thể kích hoạt lại: mã \"" + originalCode
                        + "\" đã được chi nhánh khác sử dụng. Vui lòng đổi mã khác trước khi kích hoạt.");
            }
            existing.setBranchCode(originalCode);
            existing.setSuspendedCode(null);
        }

        // Chỉ cho phép kích hoạt lại nếu đã hoàn tất đủ 5 bước.
        boolean allDone = Boolean.TRUE.equals(existing.getStep1Done())
                && Boolean.TRUE.equals(existing.getStep2Done())
                && Boolean.TRUE.equals(existing.getStep3Done())
                && Boolean.TRUE.equals(existing.getStep4Done())
                && Boolean.TRUE.equals(existing.getStep5Done());
        existing.setCreationStatus(allDone ? "COMPLETED" : "DRAFT");
        existing.setIsActive(true);
        existing.setUpdatedAt(java.time.LocalDateTime.now());
        Branch saved = branchRepository.save(existing);

        // ── BẬT LẠI TẤT CẢ PHÒNG ĐÃ BỊ TẮT LÚC TẠM NGỪNG ──
        // suspend() đã đánh dấu is_deleted = true + gắn hậu tố _OFF_<id> vào
        // room_code. Vì Room có @SQLRestriction("is_deleted = false"), phải dùng
        // native query để tìm lại các phòng đã xoá mềm này.
        // Hậu tố có thể kèm số đếm (_OFF_<id>_1, _OFF_<id>_2, ...) nên phải gỡ
        // theo mẫu thay vì so khớp chuỗi cố định.
        String suffix = "_OFF_" + saved.getId();
        List<com.stayhub.api.entity.Room> offRooms =
                roomRepository.findByBranchIdIncludingDeleted(saved.getId());
        for (com.stayhub.api.entity.Room room : offRooms) {
            room.setIsDeleted(false);
            String roomCode = room.getRoomCode();
            if (roomCode != null) {
                String stripped = stripOffSuffix(roomCode, saved.getId());
                // Chỉ khôi phục mã gốc nếu chưa bị phòng KHÁC chiếm dụng, tránh
                // vi phạm UNIQUE(room_code) khi UPDATE.
                if (stripped != null && !stripped.equals(roomCode)
                        && roomRepository.findByRoomCodeIncludingDeleted(stripped)
                                .filter(other -> !other.getId().equals(room.getId()))
                                .isEmpty()) {
                    room.setRoomCode(stripped);
                }
            }
            // Phòng chưa từng cho thuê thì đưa về trạng thái chờ cấu hình.
            if (room.getStatus() == com.stayhub.api.entity.RoomStatus.DONG_CUA) {
                room.setStatus(com.stayhub.api.entity.RoomStatus.KHOA_CHO_CAP_NHAT);
            }
            roomPostRepository.findByRoomId(room.getId()).ifPresent(post -> {
                if ("HIDDEN".equals(post.getStatus())) {
                    post.setStatus("ACTIVE");
                    roomPostRepository.save(post);
                }
            });
        }
        roomRepository.saveAll(offRooms);

        // ── BẬT LẠI TIỆN ÍCH CHUNG ──
        List<com.stayhub.api.entity.SharedFacility> facilities =
                sharedFacilityRepository.findByBranchIdIncludingDeleted(saved.getId());
        for (com.stayhub.api.entity.SharedFacility fac : facilities) {
            fac.setIsDeleted(false);
        }
        sharedFacilityRepository.saveAll(facilities);

        // ── GỠ _OFF KHỎI MỌI CODE/ĐỊNH DANH CHUỖI THUỘC CHI NHÁNH ──
        removeOffSuffixFromBranchEntities(saved.getId());

        return saved;
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public Branch update(Long id, Branch updated) {
        Branch existing = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Khﺣﺑng tﺣ؛m thﻕﭨ۴y dﺣ۲y trﻕﭨ ID: " + id));

        // ── CHỐT CHẶN AN TOÀN ──
        // Chi nhánh đã NGỪNG HOẠT ĐỘNG (SUSPENDED) là dữ liệu LỊCH SỬ, chỉ được
        // kích hoạt lại — KHÔNG được ghi đè cấu trúc. Nếu không chặn, một client
        // còn giữ ID chi nhánh OFF (ví dụ do bug chọn nhầm `branches.last`) sẽ
        // ghi cấu trúc phòng mới đè lên chi nhánh cũ, và Bước 3 lần sau nạp lại
        // sẽ thấy phòng của chi nhánh cũ.
        if ("SUSPENDED".equals(existing.getCreationStatus())) {
            throw new IllegalStateException(
                "Chi nhánh đã ngừng hoạt động, không thể chỉnh sửa cấu trúc. "
                + "Vui lòng kích hoạt lại chi nhánh hoặc tạo chi nhánh mới.");
        }

        // CHỈ ghi đè khi payload THỰC SỰ có giá trị — tránh xoá dữ liệu khi
        // frontend chỉ gửi 1 phần (ví dụ bước 2 chỉ gửi {'description': ...}).
        if (updated.getBranchName() != null) existing.setBranchName(updated.getBranchName());
        if (updated.getAddress() != null) existing.setAddress(updated.getAddress());
        if (updated.getAddressOld() != null) {
            existing.setAddressOld(updated.getAddressOld());
            com.stayhub.api.service.AddressMapper.Address3Tier mapped = com.stayhub.api.service.AddressMapper.mapTo3Tier(updated.getAddressOld());
            existing.setLegalProvince(mapped.getProvince());
            existing.setLegalWard(mapped.getWard());
            existing.setLegalDistrict(""); // Omit district as per new rule
        }
        if (updated.getLegalProvince() != null) existing.setLegalProvince(updated.getLegalProvince());
        if (updated.getLegalDistrict() != null) existing.setLegalDistrict(updated.getLegalDistrict());
        if (updated.getLegalWard() != null) existing.setLegalWard(updated.getLegalWard());
        if (updated.getLatitude() != null) existing.setLatitude(updated.getLatitude());
        if (updated.getLongitude() != null) existing.setLongitude(updated.getLongitude());
        if (updated.getNumberOfFloors() != null) existing.setNumberOfFloors(updated.getNumberOfFloors());
        if (updated.getTotalRooms() != null) existing.setTotalRooms(updated.getTotalRooms());
        if (updated.getElectricityPrice() != null) existing.setElectricityPrice(updated.getElectricityPrice());
        if (updated.getWaterPrice() != null) existing.setWaterPrice(updated.getWaterPrice());
        if (updated.getBillingDay() != null) existing.setBillingDay(updated.getBillingDay());
        if (updated.getMinLeaseDays() != null) existing.setMinLeaseDays(updated.getMinLeaseDays());
        if (updated.getInternetFee() != null) existing.setInternetFee(updated.getInternetFee());
        if (updated.getParkingFee() != null) existing.setParkingFee(updated.getParkingFee());
        if (updated.getGarbageFee() != null) existing.setGarbageFee(updated.getGarbageFee());
        if (updated.getPetPolicy() != null) existing.setPetPolicy(updated.getPetPolicy());
        if (updated.getRoommatePolicy() != null) existing.setRoommatePolicy(updated.getRoommatePolicy());
        if (updated.getClosingTime() != null) existing.setClosingTime(updated.getClosingTime());
        if (updated.getCookingPolicy() != null) existing.setCookingPolicy(updated.getCookingPolicy());
        if (updated.getEvChargingAllowed() != null) existing.setEvChargingAllowed(updated.getEvChargingAllowed());
        if (updated.getEvChargeType() != null) existing.setEvChargeType(updated.getEvChargeType());
        if (updated.getEvFixedPrice() != null) existing.setEvFixedPrice(updated.getEvFixedPrice());
        if (updated.getDepositMonths() != null) existing.setDepositMonths(updated.getDepositMonths());
        if (updated.getPropertyType() != null) existing.setPropertyType(updated.getPropertyType());
        if (updated.getCreationStatus() != null) existing.setCreationStatus(updated.getCreationStatus());
        if (updated.getPois() != null) existing.setPois(updated.getPois());

        if (updated.getCoverImages() != null && updated.getCoverImages().startsWith("[")) {
            try {
                java.util.List<String> b64List = objectMapper.readValue(updated.getCoverImages(), new com.fasterxml.jackson.core.type.TypeReference<java.util.List<String>>() {});
                java.util.List<String> urls = new java.util.ArrayList<>();
                for (String b64 : b64List) {
                    // Check if it's already a URL
                    if (b64.startsWith("http")) {
                        urls.add(b64);
                    } else {
                        String url = cloudStorageService.uploadBase64(b64);
                        if (url != null) urls.add(url);
                    }
                }
                existing.setCoverImages(objectMapper.writeValueAsString(urls));
                if (!urls.isEmpty()) {
                    existing.setCoverImage(urls.get(0));
                }
            } catch (Exception e) {
                throw new RuntimeException("Lﻕﭨi xﻕﭨ­ lﺣﺛ ﻕﭦ۲nh: " + e.getMessage());
            }
        } else if (updated.getCoverImage() != null) {
             existing.setCoverImage(updated.getCoverImage());
        }

        // Process pcccImages base64 to URLs
        if (updated.getPcccImages() != null && updated.getPcccImages().startsWith("[")) {
            try {
                java.util.List<String> b64List = objectMapper.readValue(updated.getPcccImages(), new com.fasterxml.jackson.core.type.TypeReference<java.util.List<String>>() {});
                java.util.List<String> urls = new java.util.ArrayList<>();
                for (String b64 : b64List) {
                    if (b64.startsWith("http")) {
                        urls.add(b64); // Giﻕﭨﺁ nguyﺣ۹n URL cﺧ۸
                    } else {
                        String url = cloudStorageService.uploadBase64(b64);
                        if (url != null) urls.add(url);
                    }
                }
                existing.setPcccImages(objectMapper.writeValueAsString(urls));
            } catch (Exception e) {
                throw new RuntimeException("Lﻕﭨi xﻕﭨ­ lﺣﺛ ﻕﭦ۲nh PCCC: " + e.getMessage());
            }
        } else if (updated.getPcccImages() != null) {
            // CHỈ ghi đè khi payload THỰC SỰ có pcccImages — nếu không, các bước
            // khác (vd bước 3 chỉ gửi description) sẽ vô tình xoá ảnh PCCC.
            existing.setPcccImages(updated.getPcccImages());
        }
        // CHỈ cập nhật hasPccc khi payload có gửi — nếu gán null sẽ vi phạm
        // ràng buộc NOT NULL của cột has_pccc và làm rollback toàn bộ giao dịch
        // (chính là lỗi "không thể lưu cấu trúc phòng" ở bước 3).
        if (updated.getHasPccc() != null) {
            existing.setHasPccc(updated.getHasPccc());
        }

        Branch saved = branchRepository.save(existing);

        // Copy description from request so floor/room JSON is available for processing
        // (floors = bước 3, sharedAssets = bước 2 — xử lý độc lập)
        String incomingDescription = updated.getDescription();
        if (incomingDescription != null
                && (incomingDescription.contains("\"floors\"")
                    || incomingDescription.contains("\"sharedAssets\"")
                    || incomingDescription.contains("\"branchAmenities\""))) {
            try {
                com.fasterxml.jackson.databind.JsonNode meta = objectMapper.readTree(incomingDescription);

                // 0. Process Branch Amenities → map giá tiện ích (Wifi/Gửi xe/Rác…)
                //    sang các cột phí của chi nhánh (xem applyAmenityFees).
                applyAmenityFees(saved, meta);
                branchRepository.save(saved);

                // 1. Process Shared WCs (Smart Sync)
                java.util.Map<String, com.stayhub.api.entity.SharedFacility> wcMap = new java.util.HashMap<>();
                // CHỈ lấy các facility loại WC — tránh đụng tới tài sản chung (ASSET).
                // WC cũ có thể mang type null nên loại trừ ASSET thay vì bắt buộc == "WC".
                java.util.List<com.stayhub.api.entity.SharedFacility> oldWcs = sharedFacilityRepository.findByBranchId(saved.getId())
                    .stream()
                    .filter(f -> !"ASSET".equalsIgnoreCase(f.getType()))
                    .collect(java.util.stream.Collectors.toList());
                java.util.List<com.stayhub.api.entity.SharedFacility> wcsToKeep = new java.util.ArrayList<>();

                if (meta.has("sharedWcs")) {
                    for (com.fasterxml.jackson.databind.JsonNode wcNode : meta.get("sharedWcs")) {
                        String tempId = wcNode.get("tempId").asText();
                        com.stayhub.api.entity.SharedFacility facility = oldWcs.stream()
                            .filter(w -> tempId.equals(w.getNotes()))
                            .findFirst().orElse(null);

                        if (facility == null) {
                            facility = com.stayhub.api.entity.SharedFacility.builder()
                                .branchId(saved.getId())
                                .type("WC")
                                .build();
                        }
                        facility.setName(wcNode.get("name").asText());
                        facility.setNotes(tempId);
                        facility = sharedFacilityRepository.save(facility);
                        wcsToKeep.add(facility);
                        wcMap.put(tempId, facility);
                    }
                }
                // CHỈ xoá WC khi payload THỰC SỰ có "sharedWcs". Nếu payload chỉ
                // chứa "floors" (vd lưu phòng) mà thiếu "sharedWcs", việc xoá sẽ
                // quét sạch toàn bộ WC — đây chính là lỗi "mất WC".
                if (meta.has("sharedWcs")) {
                    // So sánh theo ID thay vì removeAll(entity): SharedFacility dùng
                    // Lombok @Data nên equals/hashCode phụ thuộc collection `rooms`.
                    java.util.Set<Long> keepWcIds = wcsToKeep.stream()
                        .map(com.stayhub.api.entity.SharedFacility::getId)
                        .filter(java.util.Objects::nonNull)
                        .collect(java.util.stream.Collectors.toSet());
                    java.util.List<com.stayhub.api.entity.SharedFacility> wcsToDelete = oldWcs.stream()
                        .filter(w -> w.getId() != null && !keepWcIds.contains(w.getId()))
                        .collect(java.util.stream.Collectors.toList());
                    if (!wcsToDelete.isEmpty()) {
                        sharedFacilityRepository.deleteAll(wcsToDelete);
                    }
                }

                // 1b. Process Shared Assets (Smart Sync theo tên)
                java.util.List<com.stayhub.api.entity.SharedFacility> oldAssets = sharedFacilityRepository.findByBranchId(saved.getId())
                    .stream().filter(f -> "ASSET".equals(f.getType())).collect(java.util.stream.Collectors.toList());
                java.util.List<com.stayhub.api.entity.SharedFacility> assetsToKeep = new java.util.ArrayList<>();

                if (meta.has("sharedAssets")) {
                    for (com.fasterxml.jackson.databind.JsonNode assetNode : meta.get("sharedAssets")) {
                        String assetName = assetNode.has("name") ? assetNode.get("name").asText() : "";
                        if (assetName == null || assetName.trim().isEmpty()) continue;
                        com.stayhub.api.entity.SharedFacility asset = oldAssets.stream()
                            .filter(a -> assetName.equals(a.getName()))
                            .findFirst().orElse(null);
                        if (asset == null) {
                            asset = com.stayhub.api.entity.SharedFacility.builder()
                                .branchId(saved.getId())
                                .type("ASSET")
                                .build();
                        }
                        asset.setName(assetName);
                        asset.setNotes(assetNode.has("note") ? assetNode.get("note").asText() : null);
                        asset.setImages(assetNode.has("images") ? assetNode.get("images").toString() : null);
                        asset.setEquipment(assetNode.has("quantity") ? assetNode.get("quantity").asText() : "1");
                        asset = sharedFacilityRepository.save(asset);
                        assetsToKeep.add(asset);
                    }
                }
                // So sánh theo ID thay vì removeAll(entity): SharedFacility dùng
                // Lombok @Data nên equals/hashCode phụ thuộc collection `rooms`,
                // khiến removeAll có thể bỏ sót và xoá nhầm tài sản chung.
                java.util.Set<Long> keepAssetIds = assetsToKeep.stream()
                    .map(com.stayhub.api.entity.SharedFacility::getId)
                    .filter(java.util.Objects::nonNull)
                    .collect(java.util.stream.Collectors.toSet());
                java.util.List<com.stayhub.api.entity.SharedFacility> assetsToDelete = oldAssets.stream()
                    .filter(a -> a.getId() != null && !keepAssetIds.contains(a.getId()))
                    .collect(java.util.stream.Collectors.toList());
                if (!assetsToDelete.isEmpty()) {
                    sharedFacilityRepository.deleteAll(assetsToDelete);
                }

                // 2. Process Floors and Rooms (Smart Sync)
                // CHỈ xử lý phòng khi payload thực sự có "floors" — nếu chỉ lưu
                // tài sản chung (bước 2) thì KHÔNG được đụng tới phòng, tránh xoá nhầm.
                if (meta.has("floors")) {
                    java.util.List<com.stayhub.api.entity.Room> oldRooms = roomRepository.findByBranchId(saved.getId());
                    java.util.List<com.stayhub.api.entity.Room> roomsToKeep = new java.util.ArrayList<>();
                    java.util.List<com.stayhub.api.entity.Room> newRooms = new java.util.ArrayList<>();

                    // Tiền tố roomCode phải ổn định & duy nhất. Chi nhánh NHÁP có thể
                    // chưa có branchCode (null) → nếu ghép thẳng sẽ ra "null_101" và
                    // phòng thứ 2 trùng UNIQUE(room_code) khiến TOÀN BỘ khối tạo phòng
                    // ném lỗi rồi bị nuốt im lặng ⇒ bước 4 không thấy phòng nào.
                    String codePrefix = saved.getBranchCode();
                    if (codePrefix == null || codePrefix.trim().isEmpty()) {
                        codePrefix = "BR" + saved.getId();
                    }

                    for (com.fasterxml.jackson.databind.JsonNode fNode : meta.get("floors")) {
                        int fNum = fNode.has("floorNumber") ? fNode.get("floorNumber").asInt() : 1;
                        if (fNode.has("rooms")) {
                            for (com.fasterxml.jackson.databind.JsonNode rNode : fNode.get("rooms")) {
                                String rName = rNode.has("tempId") ? rNode.get("tempId").asText()
                                    : (rNode.has("code") ? rNode.get("code").asText() : "");
                                if (rName == null || rName.trim().isEmpty()) continue;
                                // roomCode duy nhất toàn hệ thống: luôn ghép branchCode.
                                // Không dùng code thô từ client để tránh trùng giữa chi nhánh.
                                String rCode = codePrefix + "_" + rName;
                                boolean isSelfContained = rNode.has("isSelfContained") && rNode.get("isSelfContained").asBoolean();
                                String wcId = rNode.has("sharedWcId") && !rNode.get("sharedWcId").isNull() ? rNode.get("sharedWcId").asText() : null;
                                // Giá/diện tích có thể nằm trực tiếp trên node HOẶC trong
                                // detailedInfo (payload của RoomConfigBottomSheet).
                                com.fasterxml.jackson.databind.JsonNode detailNode =
                                    rNode.has("detailedInfo") && rNode.get("detailedInfo").isObject()
                                        ? rNode.get("detailedInfo") : null;
                                Double rPrice = rNode.has("price") ? rNode.get("price").asDouble()
                                    : (detailNode != null && detailNode.has("price") ? detailNode.get("price").asDouble() : 0.0);
                                Double rArea = rNode.has("area") ? rNode.get("area").asDouble()
                                    : (detailNode != null && detailNode.has("area") ? detailNode.get("area").asDouble() : 0.0);

                                com.stayhub.api.entity.Room r = oldRooms.stream()
                                    .filter(old -> rCode.equals(old.getRoomCode()))
                                    .findFirst().orElse(null);

                                boolean isNew = false;
                                if (r == null) {
                                    // Không thấy trong danh sách phòng "sống" — nhưng có thể
                                    // tồn tại một phòng ĐÃ XOÁ MỀM cùng room_code. Ràng buộc
                                    // UNIQUE(rooms.room_code) KHÔNG phải partial index nên nó
                                    // vẫn chặn dòng đã xoá mềm ⇒ INSERT mới sẽ ném
                                    // "duplicate key value violates unique constraint".
                                    // Hồi sinh dòng cũ thay vì tạo mới.
                                    //
                                    // CẢNH BÁO: chỉ được hồi sinh khi dòng cũ THUỘC CHÍNH
                                    // chi nhánh này (hoặc chưa gán chi nhánh). Nếu hồi sinh
                                    // một phòng của chi nhánh KHÁC (ví dụ chi nhánh cũ đã
                                    // tạm ngừng nhưng room_code chưa kịp đổi hậu tố
                                    // `_OFF_<id>`), phòng đó sẽ bị "cướp" sang chi nhánh mới
                                    // kèm toàn bộ cấu hình cũ ⇒ bước 3 của chi nhánh mới
                                    // hiển thị sẵn dữ liệu của chi nhánh cũ.
                                    java.util.Optional<com.stayhub.api.entity.Room> softDeleted =
                                        roomRepository.findByRoomCodeIncludingDeleted(rCode);
                                    boolean belongsHere = softDeleted.isPresent()
                                        && (softDeleted.get().getBranchId() == null
                                            || softDeleted.get().getBranchId().equals(saved.getId()));
                                    if (belongsHere) {
                                        r = softDeleted.get();
                                        r.setIsDeleted(false);
                                        r.setOwnerId(saved.getOwnerId());
                                        r.setBranchId(saved.getId());
                                        r.setAddress(saved.getAddress());
                                        r.setAddressOld(saved.getAddressOld());
                                        // Phòng hồi sinh coi như phòng cũ ⇒ đưa vào roomsToKeep
                                        // để không bị xoá ở bước dọn dẹp phía sau.
                                        isNew = false;
                                    } else {
                                        r = com.stayhub.api.entity.Room.builder()
                                                .ownerId(saved.getOwnerId())
                                                .branchId(saved.getId())
                                                .roomCode(rCode)
                                                .address(saved.getAddress())
                                                .addressOld(saved.getAddressOld())
                                                .status(com.stayhub.api.entity.RoomStatus.KHOA_CHO_CAP_NHAT)
                                                .sharedFacilities(new java.util.ArrayList<>())
                                                .build();
                                        isNew = true;
                                    }
                                } else {
                                    // Update address for existing rooms in case branch address changed
                                    r.setAddress(saved.getAddress());
                                    r.setAddressOld(saved.getAddressOld());
                                }
                                r.setRoomName(rName);
                                r.setFloor(fNum);
                                r.setPrice(rPrice);
                                r.setFloorArea(rArea);
                                r.setElectricityPrice(saved.getElectricityPrice());
                                r.setWaterPrice(saved.getWaterPrice());
                                r.setServiceFee(saved.getServiceFee());

                                java.util.Map<String, Object> rInfo = r.getDetailedInfo();
                                if (rInfo == null) rInfo = new java.util.HashMap<>();
                                // Gộp toàn bộ cấu hình chi tiết do bước 3/4 gửi lên
                                // (giá, diện tích, tiện ích, ảnh…) thay vì chỉ ghi đè
                                // 2 khoá — nếu không, cấu hình chi tiết sẽ bị mất.
                                if (detailNode != null) {
                                    java.util.Iterator<java.util.Map.Entry<String, com.fasterxml.jackson.databind.JsonNode>> it =
                                        detailNode.fields();
                                    while (it.hasNext()) {
                                        java.util.Map.Entry<String, com.fasterxml.jackson.databind.JsonNode> en = it.next();
                                        Object value = objectMapper.convertValue(en.getValue(), Object.class);
                                        // Ảnh phòng do RoomConfigBottomSheet gửi lên là base64
                                        // thô. Nếu lưu thẳng vào jsonb `detailed_info` (và cả
                                        // `description`) sẽ phình dữ liệu cực lớn, dễ gây timeout
                                        // hoặc lỗi khi lưu cấu trúc. Upload lên cloud rồi thay bằng URL.
                                        if (("photos".equals(en.getKey()) || "featurePhotos".equals(en.getKey()))
                                                && value != null) {
                                            value = uploadBase64Images(value);
                                        }
                                        rInfo.put(en.getKey(), value);
                                    }
                                }
                                rInfo.put("isSelfContained", isSelfContained);
                                if (saved.getWaterPricingType() != null) {
                                    rInfo.put("waterPricingType", saved.getWaterPricingType().name());
                                }
                                r.setDetailedInfo(rInfo);

                                // Room.sharedFacilities là phía INVERSE — chỉ dùng để
                                // gom nhóm trong bộ nhớ cho linkFacilitiesOwningSide().
                                // KHÔNG mutate collection managed của entity đang được
                                // Hibernate theo dõi (clear/add) vì điều đó làm bẩn
                                // persistence context và có thể khiến flush sau đó
                                // cố ghi vào bảng nối theo cách không mong muốn.
                                java.util.List<com.stayhub.api.entity.SharedFacility> linkedWcs =
                                    new java.util.ArrayList<>();
                                if (!isSelfContained && wcId != null && wcMap.containsKey(wcId)) {
                                    linkedWcs.add(wcMap.get(wcId));
                                }
                                r.setSharedFacilities(linkedWcs);

                                if (isNew) {
                                    newRooms.add(r);
                                } else {
                                    roomsToKeep.add(r);
                                }
                            }
                        }
                    }

                    // So sánh theo ID thay vì removeAll(entity): Room dùng
                    // @Getter @Setter nên equals là identity, nhưng khi cùng một
                    // phòng xuất hiện ở nhiều managed instance (EntityGraph +
                    // EAGER collection) thì removeAll có thể bỏ sót → xoá nhầm
                    // phòng vừa giữ. Dùng tập ID để chắc chắn.
                    java.util.Set<Long> keepRoomIds = roomsToKeep.stream()
                        .map(com.stayhub.api.entity.Room::getId)
                        .filter(java.util.Objects::nonNull)
                        .collect(java.util.stream.Collectors.toSet());
                    java.util.List<com.stayhub.api.entity.Room> roomsToDelete = oldRooms.stream()
                        .filter(r -> r.getId() != null && !keepRoomIds.contains(r.getId()))
                        .collect(java.util.stream.Collectors.toList());
                    if (!roomsToDelete.isEmpty()) {
                        boolean hasRentedRoom = roomsToDelete.stream().anyMatch(r ->
                            r.getStatus() == com.stayhub.api.entity.RoomStatus.DA_THUE ||
                            r.getCurrentContractId() != null ||
                            r.getCurrentTenantId() != null
                        );
                        if (hasRentedRoom) {
                            throw new IllegalStateException("Không thể xoá/bỏ phòng đang có khách thuê. Vui lòng thanh lý hợp đồng trước.");
                        }
                        // Dọn bảng nối room_shared_facilities bằng native SQL TRƯỚC
                        // khi xoá phòng. Room.sharedFacilities là phía INVERSE nên
                        // Hibernate không tự dọn; nếu để lại, thao tác xoá phòng có
                        // thể vướng khoá ngoại hoặc để lại rác trong bảng nối.
                        java.util.List<Long> deleteRoomIds = roomsToDelete.stream()
                            .map(com.stayhub.api.entity.Room::getId)
                            .filter(java.util.Objects::nonNull)
                            .collect(java.util.stream.Collectors.toList());
                        if (!deleteRoomIds.isEmpty()) {
                            entityManager.createNativeQuery(
                                    "DELETE FROM room_shared_facilities WHERE room_id IN (:rids)")
                                .setParameter("rids", deleteRoomIds)
                                .executeUpdate();
                            // Xoá bulk thay vì deleteAll(entity): tránh Hibernate
                            // cố dọn collection EAGER phía INVERSE khiến flush lỗi.
                            roomRepository.deleteByIdIn(deleteRoomIds);
                            // Đồng bộ persistence context: các entity vừa bị xoá bulk
                            // vẫn nằm trong session và sẽ gây lỗi khi flush.
                            for (com.stayhub.api.entity.Room deleted : roomsToDelete) {
                                entityManager.detach(deleted);
                            }
                        }
                    }

                    if (!newRooms.isEmpty()) {
                        roomRepository.saveAll(newRooms);
                    }
                    if (!roomsToKeep.isEmpty()) {
                        roomRepository.saveAll(roomsToKeep);
                    }

                    // Persist quan hệ phòng ↔ WC ở phía OWNING (SharedFacility.rooms).
                    //
                    // LUÔN gọi kể cả khi wcMap rỗng: nếu bỏ qua, các phòng vừa
                    // chuyển từ "dùng WC chung" sang "khép kín" sẽ còn sót bản ghi
                    // cũ trong bảng nối room_shared_facilities. Phương thức này cũng
                    // dọn sạch liên kết cũ của mọi phòng trước khi ghi lại.
                    java.util.List<com.stayhub.api.entity.Room> allLinkedRooms =
                        new java.util.ArrayList<>(newRooms);
                    allLinkedRooms.addAll(roomsToKeep);
                    linkFacilitiesOwningSide(wcMap.values(), allLinkedRooms);

                    saved.setTotalRooms(newRooms.size() + roomsToKeep.size());
                } // end if (meta.has("floors"))

                saved.setDescription(incomingDescription); // Bﻕﭦ۱O TﻕﭨN JSON!
                branchRepository.save(saved);

            } catch (IllegalStateException e) {
                throw e; // Pass through validation error
            } catch (Exception e) {
                // KHÔNG được nuốt lỗi im lặng: nếu tạo phòng thất bại mà ta vẫn lưu
                // description thì bước 3 báo "đã lưu" nhưng bước 4 trống trơn.
                // Ghi log rõ ràng rồi ném lại để transaction rollback và UI hiện lỗi.
                org.slf4j.LoggerFactory.getLogger(BranchServiceImpl.class)
                    .error("Lỗi đồng bộ cấu trúc phòng/WC cho chi nhánh {}: {}",
                        saved.getId(), e.getMessage(), e);
                throw new IllegalStateException(
                    "Không thể lưu cấu trúc phòng: " + e.getMessage(), e);
            }
        } else if (incomingDescription != null && !incomingDescription.isEmpty()) {
            saved.setDescription(incomingDescription);
            branchRepository.save(saved);
        }

        return saved;
    }


    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy dãy trọ ID: " + id));

        // ────────────────────────────────────────────────────────────────
        // PHAN BIET 2 LUONG THEO TRANG THAI:
        //   • Dang hoat dong (COMPLETED) -> "NGUNG HOAT DONG" (SUSPENDED):
        //       day la xoa mem, GIU LAI du lieu lich su, va them hau to
        //       _OFF_<id> vao branch_code de giai phong ma goc cho chi nhanh moi.
        //   • Dang khoi tao (DRAFT) -> "HUY": chi nhanh coi nhu CHUA TUNG
        //       ton tai, xoa cung (hard delete) de giai phong hoan toan ma.
        // ────────────────────────────────────────────────────────────────
        boolean isDraft = !"COMPLETED".equals(branch.getCreationStatus());

        if (isDraft) {
            cancelDraft(id);
            return;
        }

        // Disable associated rooms
        List<com.stayhub.api.entity.Room> rooms = roomRepository.findByBranchId(id);

        // Prevent deletion if any room is rented or has active contracts
        boolean hasRentedRoom = rooms.stream().anyMatch(r ->
            r.getStatus() == com.stayhub.api.entity.RoomStatus.DA_THUE ||
            r.getCurrentContractId() != null ||
            r.getCurrentTenantId() != null
        );
        if (hasRentedRoom) {
            throw new IllegalStateException("Không thể ngừng hoạt động chi nhánh vì vẫn còn khách đang thuê hoặc hợp đồng còn thời hạn. Vui lòng thanh lý hợp đồng và trả phòng trước.");
        }

        // Prevent deletion if there are unresolved complaints/disputes
        List<com.stayhub.api.entity.Complaint> complaints = complaintRepository.findByBranchIdOrderByCreatedAtDesc(id);
        boolean hasActiveComplaints = complaints.stream().anyMatch(c ->
            "PENDING".equals(c.getStatus()) || "PROCESSING".equals(c.getStatus())
        );
        if (hasActiveComplaints) {
            throw new IllegalStateException("Không thể ngừng hoạt động chi nhánh vì đang có sự cố hoặc khiếu nại chưa được giải quyết (tranh chấp).");
        }

        String branchName = branch.getBranchName();
        Long ownerId = branch.getOwnerId();
        int roomCount = rooms.size();

        // Chuyen sang trang thai NGUNG HOAT DONG (SUSPENDED) thay vi xoa mem.
        // Ly do: xoa mem lam branch bien mat khoi moi truy van JPA
        // (@SQLRestriction is_deleted = false) nhung branch_code van chiem
        // UNIQUE INDEX -> gay loi trung ma khi tao chi nhanh moi.
        branch.setIsActive(false);
        branch.setIsDeleted(false);
        branch.setCreationStatus("SUSPENDED");
        branch.setUpdatedAt(java.time.LocalDateTime.now());

        // Hau to _OFF_<id> dung CHUNG cho ca branch va room, chi gan MOT LAN.
        // Nếu trùng ID với chi nhánh đã OFF trước đó thì thêm số đếm để tránh
        // vi phạm UNIQUE(branch_code).
        String currentCode = branch.getBranchCode() == null ? "" : branch.getBranchCode();
        String suffix = resolveUniqueOffSuffix(branch.getId(), currentCode);
        if (!currentCode.contains("_OFF_") && !currentCode.contains("_DEL_")) {
            // Lưu mã gốc để resume() có thể khôi phục chính xác (kể cả khi hậu tố
            // có kèm số đếm do trùng ID).
            if (branch.getSuspendedCode() == null && !currentCode.isEmpty()) {
                branch.setSuspendedCode(currentCode);
            }
            branch.setBranchCode(currentCode + suffix);
        }
        branchRepository.save(branch);

        for (com.stayhub.api.entity.Room room : rooms) {
            room.setStatus(com.stayhub.api.entity.RoomStatus.DONG_CUA);
            room.setIsDeleted(true);
            String roomCode = room.getRoomCode();
            if (roomCode != null && !roomCode.contains("_OFF_") && !roomCode.contains("_DEL_")) {
                // room_code có UNIQUE INDEX riêng -> phải tính hậu tố riêng cho
                // từng phòng để tránh đụng mã phòng cũ khi chi nhánh thứ 2 trùng ID.
                String roomSuffix = resolveUniqueRoomOffSuffix(branch.getId(), roomCode);
                room.setRoomCode(roomCode + roomSuffix);
            }

            // Ẩn bài đăng chợ trọ nếu có
            roomPostRepository.findByRoomId(room.getId()).ifPresent(post -> {
                post.setStatus("HIDDEN");
                roomPostRepository.save(post);
            });
        }
        roomRepository.saveAll(rooms);

        // Soft delete all Shared Facilities
        List<com.stayhub.api.entity.SharedFacility> facilities = sharedFacilityRepository.findByBranchId(id);
        for (com.stayhub.api.entity.SharedFacility fac : facilities) {
            fac.setIsDeleted(true);
        }
        sharedFacilityRepository.saveAll(facilities);

        // ── GẮN _OFF VÀO MỌI CODE/ĐỊNH DANH CHUỖI THUỘC CHI NHÁNH ──
        applyOffSuffixToBranchEntities(branch.getId(), suffix);

        // 🔔 Gửi thông báo cho chủ nhà
        try {
            com.fasterxml.jackson.databind.ObjectMapper objectMapper = new com.fasterxml.jackson.databind.ObjectMapper();
            String meta = objectMapper.writeValueAsString(java.util.Map.of(
                "action", "NAVIGATE",
                "screen", "OWNER_DASHBOARD"
            ));
            Notification notif = Notification.builder()
                .receiverId(ownerId)
                .title("⏸️ Chi nhánh đã ngừng hoạt động")
                .content("Chi nhánh \"" + branchName + "\" và " + roomCount + " phòng liên quan đã chuyển sang trạng thái ngừng hoạt động. Mã chi nhánh đã được giải phóng để bạn có thể tạo chi nhánh mới cùng địa chỉ.")
                .type(NotificationType.BRANCH_DELETED)
                .scope(NotificationScope.INDIVIDUAL)
                .isActionable(false)
                .actionMetadata(meta)
                .build();
            notificationRepository.save(notif);
        } catch (Exception ignore) { log.warn("Ignored exception in BranchServiceImpl: ", ignore); }
    }

    /**
     * HUY chi nhanh dang khoi tao (DRAFT).
     * Chi nhanh o trang thai DRAFT coi nhu CHUA TUNG ton tai:
     *   - Xoa cung (hard delete) ban ghi branch de giai phong branch_code.
     *   - Xoa cung cac phong / khu ve sinh chung / bai dang gan voi no.
     * Nho vay ma chi nhanh duoc tra ve hoan toan cho lan tao moi tiep theo,
     * khong con tinh trang "bao chua trung nhung INSERT lai vi pham unique".
     */
    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public void cancelDraft(Long id) {
        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh ID: " + id));

        if ("COMPLETED".equals(branch.getCreationStatus())) {
            throw new IllegalStateException("Chi nhánh đã hoàn tất, không thể hủy. Vui lòng dùng chức năng ngừng hoạt động.");
        }

        // ── DỌN SẠCH MỌI DỮ LIỆU CON TRƯỚC KHI XOÁ CỨNG CHI NHÁNH ──
        // Nhiều bảng có cột branch_id tham chiếu branches(id) bằng FK. Nếu chỉ
        // xoá rooms + shared_facilities + branch thì DELETE branches sẽ ném lỗi
        // "violates foreign key constraint" và chủ nhà KHÔNG hủy được chi nhánh
        // đang khởi tạo. Vì vậy phải xoá hết các bảng con trước.
        //
        // Dùng native SQL để chắc chắn chạm đúng bảng, không phụ thuộc
        // @SQLRestriction hay quan hệ entity.
        // PHẢI dùng bản "IncludingDeleted": Room có @SQLRestriction(is_deleted=false)
        // nên findByBranchId() sẽ ẨN các phòng đã xoá mềm. Nếu bỏ sót, các dòng con
        // theo room_id và chính phòng đó vẫn còn -> DELETE branches vẫn vi phạm FK.
        List<com.stayhub.api.entity.Room> rooms = roomRepository.findByBranchIdIncludingDeleted(id);
        List<Long> roomIds = rooms.stream()
                .map(com.stayhub.api.entity.Room::getId)
                .filter(java.util.Objects::nonNull)
                .collect(java.util.stream.Collectors.toList());

        // Thu thập id voucher thuộc chi nhánh (Voucher KHÔNG có @SQLRestriction
        // nên findByBranchId() thấy đủ).
        List<Long> voucherIds = voucherRepository.findByBranchId(id).stream()
                .map(com.stayhub.api.entity.Voucher::getId)
                .filter(java.util.Objects::nonNull)
                .collect(java.util.stream.Collectors.toList());

        // ── THỨ TỰ XOÁ PHẢI TÔN TRỌNG FK (con trước, cha sau) ──
        // 1) LÁ: bảng con của voucher (theo voucher_id).
        if (!voucherIds.isEmpty()) {
            deleteByVoucherIds("voucher_usages", voucherIds);
            deleteByVoucherIds("voucher_rooms", voucherIds);
            deleteByVoucherIds("contract_vouchers", voucherIds);
        }

        // 2) LÁ: bảng con của phòng (theo room_id). Gồm cả các bảng tham chiếu
        //    contract_id (room_members, roommates, room_handovers, bills,
        //    contract_inventories, checkout_requests, violation_reports,
        //    inspection_items...) — phải xoá TRƯỚC contracts.
        if (!roomIds.isEmpty()) {
            // Danh sách CHÍNH XÁC các bảng có cột room_id (đối chiếu
            // information_schema). Chỉ liệt kê bảng thực sự tồn tại và có
            // room_id — nếu đưa bảng không có cột này vào, câu DELETE sẽ lỗi
            // "column room_id does not exist" và abort toàn bộ transaction.
            String[] roomScopedTables = {
                    "bills",
                    "checkout_requests",
                    "complaints",
                    "direct_messages",
                    "electronic_contracts",
                    "housekeeping_tasks",
                    "inspection_logs",
                    "invoices",
                    "maintenances",
                    "marketplace_posts",
                    "message_threads",
                    "rental_requests",
                    "reviews",
                    "room_assets",
                    "room_devices",
                    "room_handovers",
                    "room_inspections",
                    "room_inventory",
                    "room_members",
                    "room_posts",
                    "room_promotions",
                    "room_reports",
                    "room_service_configs",
                    "room_service_pools",
                    "room_shared_facilities",
                    "roommates",
                    "smart_devices",
                    "tenant_addon_requests",
                    "vehicles",
                    "viewing_schedules",
                    "violation_reports",
                    "voucher_rooms",
                    "wishlists"
            };
            for (String table : roomScopedTables) {
                deleteByRoomIds(table, roomIds);
            }
        }

        // 3) CHA: contracts (sau khi mọi bảng con theo contract_id/room_id đã xoá).
        if (!roomIds.isEmpty()) {
            deleteByRoomIds("contracts", roomIds);
        }

        // 4) Bảng con gắn trực tiếp với chi nhánh (theo branch_id).
        String[] branchScopedTables = {
                "branch_group_messages",
                "branch_meters",
                "branch_rules",
                "cash_sessions",
                "complaints",
                "expenses",
                "housekeeping_tasks",
                "message_threads",
                "rental_requests",
                "room_inventory",
                "service_pools",
                "staff_assignments",
                "staff_shifts",
                "staff_tasks",
                "utility_configs",
                "vehicles",
                "vouchers",
                "attendance_logs"
        };
        for (String table : branchScopedTables) {
            deleteByBranchId(table, id);
        }

        // 5) Xoá phòng (native SQL để chạm cả phòng đã xoá mềm), tiện ích chung,
        //    rồi tới chi nhánh.
        // LƯU Ý: bảng rooms KHÔNG có cột room_id (nó là bảng cha) — phải xoá
        // theo branch_id, nếu dùng deleteByRoomIds("rooms", ...) sẽ lỗi
        // "column room_id does not exist".
        deleteByBranchId("rooms", id);
        deleteByBranchId("shared_facilities", id);
        try {
            entityManager.createNativeQuery("DELETE FROM branches WHERE id = :id")
                    .setParameter("id", id)
                    .executeUpdate();
        } catch (Exception e) {
            // Ghi log rõ nguyên nhân thật (FK nào chặn) để chẩn đoán.
            log.error("[cancelDraft] Xoá branches id={} thất bại: {}", id, e.getMessage(), e);
            throw e;
        }
    }

    /**
     * Xoá cứng mọi dòng của {@code table} theo {@code branch_id} bằng native SQL.
     *
     * <p>Bỏ qua lỗi nếu bảng không tồn tại (ví dụ môi trường chưa migrate) để
     * không chặn thao tác hủy chi nhánh.</p>
     */
    private void deleteByBranchId(String table, Long branchId) {
        try {
            entityManager.createNativeQuery(
                    "DELETE FROM " + table + " WHERE branch_id = :branchId")
                    .setParameter("branchId", branchId)
                    .executeUpdate();
        } catch (Exception e) {
            // Bảng có thể không tồn tại ở một số môi trường — bỏ qua nhưng GHI LOG
            // để không che giấu lỗi FK thật sự chặn thao tác hủy chi nhánh.
            log.warn("[cancelDraft] Bỏ qua xoá bảng {} theo branch_id={}: {}", table, branchId, e.getMessage());
        }
    }

    /**
     * Xoá cứng mọi dòng của {@code table} theo {@code room_id IN (...)} bằng
     * native SQL. Bỏ qua lỗi nếu bảng không tồn tại.
     */
    private void deleteByRoomIds(String table, List<Long> roomIds) {
        if (roomIds == null || roomIds.isEmpty()) return;
        try {
            entityManager.createNativeQuery(
                    "DELETE FROM " + table + " WHERE room_id IN (:roomIds)")
                    .setParameter("roomIds", roomIds)
                    .executeUpdate();
        } catch (Exception e) {
            log.warn("[cancelDraft] Bỏ qua xoá bảng {} theo room_id ({} phòng): {}", table, roomIds.size(), e.getMessage());
        }
    }

    /**
     * Xoá cứng mọi dòng của {@code table} theo {@code voucher_id IN (...)} bằng
     * native SQL. Bỏ qua lỗi nếu bảng không tồn tại.
     */
    private void deleteByVoucherIds(String table, List<Long> voucherIds) {
        if (voucherIds == null || voucherIds.isEmpty()) return;
        try {
            entityManager.createNativeQuery(
                    "DELETE FROM " + table + " WHERE voucher_id IN (:voucherIds)")
                    .setParameter("voucherIds", voucherIds)
                    .executeUpdate();
        } catch (Exception e) {
            log.warn("[cancelDraft] Bỏ qua xoá bảng {} theo voucher_id ({} voucher): {}", table, voucherIds.size(), e.getMessage());
        }
    }

    // ─── Nearby Branch Search ─────────────────────────────────────────────────

    private static final double EARTH_RADIUS_KM = 6371.0;

    @Override
    public List<NearbyBranchDto> getNearbyBranches(double lat, double lng, double radiusKm, int maxResults) {
        double deltaLat = radiusKm / 111.0;
        double deltaLng = radiusKm / (111.0 * Math.cos(Math.toRadians(lat)));

        List<Branch> candidates = branchRepository.findActiveBranchesInBoundingBox(
                lat - deltaLat, lat + deltaLat,
                lng - deltaLng, lng + deltaLng
        );

        List<Object[]> filteredCandidates = candidates.stream()
                .map(branch -> {
                    double dist = haversineDistanceKm(lat, lng, branch.getLatitude(), branch.getLongitude());
                    return new Object[]{branch, dist};
                })
                .filter(pair -> (double) pair[1] <= radiusKm)
                .sorted(java.util.Comparator.comparingDouble(pair -> (double) pair[1]))
                .limit(maxResults)
                .collect(java.util.stream.Collectors.toList());

        List<Long> branchIds = filteredCandidates.stream()
                .map(pair -> ((Branch) pair[0]).getId())
                .collect(java.util.stream.Collectors.toList());

        java.util.Map<Long, List<com.stayhub.api.entity.Room>> roomsByBranchIdMutable = new java.util.HashMap<>();
        if (!branchIds.isEmpty()) {
            List<com.stayhub.api.entity.Room> allRooms = roomRepository.findByBranchIdIn(branchIds);
            roomsByBranchIdMutable = allRooms.stream()
                    .collect(java.util.stream.Collectors.groupingBy(com.stayhub.api.entity.Room::getBranchId));
        }
        final java.util.Map<Long, List<com.stayhub.api.entity.Room>> roomsByBranchId = roomsByBranchIdMutable;

        return filteredCandidates.stream()
                .map(pair -> {
                    Branch b = (Branch) pair[0];
                    double distKm = (double) pair[1];
                    List<com.stayhub.api.entity.Room> branchRooms = roomsByBranchId.getOrDefault(b.getId(), java.util.Collections.emptyList());

                    long availableCount = branchRooms.stream().filter(r -> "TRONG".equals(r.getStatus())).count();
                    double minPrice = branchRooms.stream().filter(r -> r.getPrice() != null && r.getPrice() > 0).mapToDouble(r -> r.getPrice()).min().orElse(0);
                    double maxPrice = branchRooms.stream().filter(r -> r.getPrice() != null && r.getPrice() > 0).mapToDouble(r -> r.getPrice()).max().orElse(0);
                    String distLabel = distKm < 1.0 ? Math.round(distKm * 1000) + " m" : String.format("%.1f km", distKm);

                    return NearbyBranchDto.builder()
                            .id(b.getId()).branchName(b.getBranchName()).branchCode(b.getBranchCode())
                            .address(b.getAddress()).addressOld(b.getAddressOld())
                            .latitude(b.getLatitude()).longitude(b.getLongitude())
                            .distanceKm(Math.round(distKm * 10.0) / 10.0).distanceLabel(distLabel)
                            .availableRooms((int) availableCount).minPrice(minPrice).maxPrice(maxPrice)
                            .electricityPrice(b.getElectricityPrice()).waterPrice(b.getWaterPrice())
                            .build();
                })
                .collect(java.util.stream.Collectors.toList());
    }

    /**
     * Ghi quan hệ phòng ↔ khu vực chung vào bảng nối room_shared_facilities.
     *
     * <p>Lý do: {@code Room.sharedFacilities} là phía INVERSE
     * ({@code @ManyToMany(mappedBy = "rooms")}), nên mọi thay đổi trên nó KHÔNG
     * được Hibernate persist. Chỉ phía OWNING ({@code SharedFacility.rooms}) mới
     * ghi được bản ghi vào bảng nối. Vì vậy phải gán room vào
     * {@code facility.getRooms()} rồi lưu lại facility.</p>
     *
     * <p>Phương thức này cũng dọn các liên kết cũ để tránh phòng bị gán trùng
     * sang nhiều WC sau khi người dùng đổi phân công ở Bước 3.</p>
     */
    /**
     * Gỡ hậu tố {@code _OFF_<branchId>} (kèm số đếm tuỳ chọn {@code _1}, {@code _2}...)
     * khỏi một chuỗi code. Trả về nguyên chuỗi nếu không khớp mẫu.
     */
    private String stripOffSuffix(String value, Long branchId) {
        if (value == null || branchId == null) return value;
        return value.replaceFirst("_OFF_" + branchId + "(_\\d+)?$", "");
    }

    /**
     * Tính hậu tố {@code _OFF_<branchId>} KHÔNG trùng với bất kỳ {@code branch_code}
     * nào đã tồn tại (kể cả chi nhánh đã xoá mềm / đã ngừng hoạt động).
     *
     * <p>Vì {@code branch_code} có UNIQUE INDEX ở tầng DB, nếu chi nhánh thứ 2
     * trùng ID với chi nhánh đã ngừng trước đó (ví dụ sau khi xoá cứng DRAFT rồi
     * tạo lại, hoặc sequence bị reset), hậu tố {@code _OFF_<id>} sẽ đụng mã cũ và
     * INSERT/UPDATE ném "duplicate key". Khi đó ta thêm số đếm: {@code _OFF_<id>1},
     * {@code _OFF_<id>2}, ... cho tới khi không còn trùng.</p>
     *
     * @param branchId ID chi nhánh đang ngừng hoạt động
     * @param baseCode mã gốc của chi nhánh (trước khi gắn hậu tố)
     * @return hậu tố duy nhất, ví dụ {@code _OFF_5} hoặc {@code _OFF_5_1}
     */
    private String resolveUniqueOffSuffix(Long branchId, String baseCode) {
        String base = "_OFF_" + branchId;
        String candidate = base;
        String prefix = baseCode == null ? "" : baseCode;
        int counter = 1;
        // Giới hạn vòng lặp để tránh treo vô hạn nếu dữ liệu bất thường.
        while (counter <= 1000
                && branchRepository.existsByBranchCodeIncludingDeleted(prefix + candidate, null)) {
            candidate = base + "_" + counter;
            counter++;
        }
        return candidate;
    }

    /**
     * Tính hậu tố {@code _OFF_<branchId>} cho {@code room_code} KHÔNG trùng với
     * bất kỳ {@code room_code} nào đã tồn tại (kể cả phòng đã xoá mềm).
     *
     * <p>{@code rooms.room_code} có UNIQUE INDEX ở tầng DB và KHÔNG phải partial
     * index — nó chặn cả dòng đã xoá mềm. Nếu chi nhánh thứ 2 trùng ID với chi
     * nhánh đã OFF trước đó, hậu tố {@code _OFF_<id>} của phòng sẽ đụng mã phòng
     * cũ và UPDATE ném "duplicate key". Khi đó thêm số đếm:
     * {@code _OFF_<id>_1}, {@code _OFF_<id>_2}, ... cho tới khi hết trùng.</p>
     *
     * @param branchId ID chi nhánh đang ngừng hoạt động
     * @param baseRoomCode mã phòng gốc (trước khi gắn hậu tố)
     * @return hậu tố duy nhất, ví dụ {@code _OFF_5} hoặc {@code _OFF_5_1}
     */
    private String resolveUniqueRoomOffSuffix(Long branchId, String baseRoomCode) {
        String base = "_OFF_" + branchId;
        String candidate = base;
        String prefix = baseRoomCode == null ? "" : baseRoomCode;
        int counter = 1;
        // Giới hạn vòng lặp để tránh treo vô hạn nếu dữ liệu bất thường.
        while (counter <= 1000
                && roomRepository.findByRoomCodeIncludingDeleted(prefix + candidate).isPresent()) {
            candidate = base + "_" + counter;
            counter++;
        }
        return candidate;
    }

    /**
     * Gắn hậu tố {@code _OFF_<branchId>} vào MỌI cột code/định danh dạng chuỗi
     * của các entity thuộc chi nhánh.
     *
     * <p>Lý do: khi chi nhánh ngừng hoạt động, không chỉ {@code branch_code} và
     * {@code room_code} bị "nhả" mà mọi mã định danh duy nhất (UNIQUE) khác của
     * entity trong chi nhánh cũng phải được đánh dấu để giải phóng mã cho chi
     * nhánh mới, đồng thời giữ lại dấu vết lịch sử.</p>
     *
     * <p>Chỉ áp dụng cho các cột code dạng chuỗi — KHÔNG đụng tới khoá chính
     * {@code Long} (không thể gắn hậu tố vào số).</p>
     */
    private void applyOffSuffixToBranchEntities(Long branchId, String suffix) {
        // ── Voucher.code (UNIQUE) ──
        // Mỗi voucher có UNIQUE INDEX riêng trên code -> phải tính hậu tố riêng
        // cho từng voucher để tránh đụng mã cũ khi chi nhánh thứ 2 trùng ID.
        List<com.stayhub.api.entity.Voucher> vouchers = voucherRepository.findByBranchId(branchId);
        for (com.stayhub.api.entity.Voucher v : vouchers) {
            String code = v.getCode();
            if (code != null && !code.contains("_OFF_") && !code.contains("_DEL_")) {
                v.setCode(code + resolveUniqueVoucherOffSuffix(branchId, code));
            }
        }
        if (!vouchers.isEmpty()) voucherRepository.saveAll(vouchers);

        // ── CashSession.sessionId (UNIQUE) ──
        // Tương tự voucher: session_id có UNIQUE INDEX riêng.
        List<com.stayhub.api.entity.CashSession> sessions = cashSessionRepository.findByBranchId(branchId);
        for (com.stayhub.api.entity.CashSession cs : sessions) {
            String sid = cs.getSessionId();
            if (sid != null && !sid.contains("_OFF_") && !sid.contains("_DEL_")) {
                cs.setSessionId(sid + resolveUniqueCashSessionOffSuffix(branchId, sid));
            }
        }
        if (!sessions.isEmpty()) cashSessionRepository.saveAll(sessions);
    }

    /**
     * Tính hậu tố {@code _OFF_<branchId>} cho {@code voucher.code} KHÔNG trùng
     * với bất kỳ code nào đã tồn tại (kể cả voucher đã xoá mềm).
     */
    private String resolveUniqueVoucherOffSuffix(Long branchId, String baseCode) {
        String base = "_OFF_" + branchId;
        String candidate = base;
        String prefix = baseCode == null ? "" : baseCode;
        int counter = 1;
        while (counter <= 1000
                && voucherRepository.existsByCodeIncludingDeleted(prefix + candidate)) {
            candidate = base + "_" + counter;
            counter++;
        }
        return candidate;
    }

    /**
     * Tính hậu tố {@code _OFF_<branchId>} cho {@code cash_session.session_id}
     * KHÔNG trùng với bất kỳ session_id nào đã tồn tại (kể cả đã xoá mềm).
     */
    private String resolveUniqueCashSessionOffSuffix(Long branchId, String baseSessionId) {
        String base = "_OFF_" + branchId;
        String candidate = base;
        String prefix = baseSessionId == null ? "" : baseSessionId;
        int counter = 1;
        while (counter <= 1000
                && cashSessionRepository.existsBySessionIdIncludingDeleted(prefix + candidate)) {
            candidate = base + "_" + counter;
            counter++;
        }
        return candidate;
    }

    /**
     * Gỡ hậu tố {@code _OFF_<branchId>} khỏi mọi cột code/định danh dạng chuỗi
     * của các entity thuộc chi nhánh khi KÍCH HOẠT LẠI.
     */
    private void removeOffSuffixFromBranchEntities(Long branchId) {
        // Chỉ gỡ hậu tố khi mã gốc chưa bị entity KHÁC chiếm dụng. Nếu đã bị
        // chiếm (ví dụ chi nhánh khác tạo voucher/session trùng mã trong lúc
        // chi nhánh này tạm ngừng), giữ nguyên mã đã gắn _OFF để tránh
        // "duplicate key" khi UPDATE.
        List<com.stayhub.api.entity.Voucher> vouchers = voucherRepository.findByBranchId(branchId);
        for (com.stayhub.api.entity.Voucher v : vouchers) {
            String current = v.getCode();
            String stripped = stripOffSuffix(current, branchId);
            if (stripped == null || stripped.equals(current)) continue;
            if (voucherRepository.existsByCodeIncludingDeleted(stripped)) continue;
            v.setCode(stripped);
        }
        if (!vouchers.isEmpty()) voucherRepository.saveAll(vouchers);

        List<com.stayhub.api.entity.CashSession> sessions = cashSessionRepository.findByBranchId(branchId);
        for (com.stayhub.api.entity.CashSession cs : sessions) {
            String current = cs.getSessionId();
            String stripped = stripOffSuffix(current, branchId);
            if (stripped == null || stripped.equals(current)) continue;
            if (cashSessionRepository.existsBySessionIdIncludingDeleted(stripped)) continue;
            cs.setSessionId(stripped);
        }
        if (!sessions.isEmpty()) cashSessionRepository.saveAll(sessions);
    }

    private void linkFacilitiesOwningSide(
            java.util.Collection<com.stayhub.api.entity.SharedFacility> facilities,
            java.util.List<com.stayhub.api.entity.Room> rooms) {
        if (rooms == null || rooms.isEmpty()) return;

        // Gom room theo facility dựa trên phía inverse đã set trong bộ nhớ.
        java.util.Map<Long, java.util.List<Long>> byFacility = new java.util.HashMap<>();
        java.util.List<Long> allRoomIds = new java.util.ArrayList<>();
        for (com.stayhub.api.entity.Room r : rooms) {
            if (r == null || r.getId() == null) continue;
            allRoomIds.add(r.getId());
            if (r.getSharedFacilities() == null) continue;
            for (com.stayhub.api.entity.SharedFacility f : r.getSharedFacilities()) {
                if (f == null || f.getId() == null) continue;
                byFacility.computeIfAbsent(f.getId(), k -> new java.util.ArrayList<>()).add(r.getId());
            }
        }

        // Ghi TRỰC TIẾP vào bảng nối room_shared_facilities bằng native SQL.
        //
        // LÝ DO KHÔNG DÙNG ENTITY: SharedFacility dùng Lombok @Data nên equals/hashCode
        // bao gồm cả collection `rooms`. Nếu gọi f.setRooms(...) rồi save(f), hashCode
        // của facility thay đổi giữa chừng, khiến các thao tác removeAll/deleteAll ở
        // luồng update không khớp được và XOÁ NHẦM toàn bộ WC. Native SQL chỉ chạm
        // bảng nối, không mutate entity nên an toàn tuyệt đối.
        //
        // Bước 1: Dọn SẠCH liên kết cũ của MỌI phòng đang xét — kể cả phòng vừa
        // chuyển sang khép kín (không còn WC). Nếu chỉ xoá theo facility_id thì
        // các phòng bỏ WC sẽ còn sót bản ghi cũ trong bảng nối.
        if (!allRoomIds.isEmpty()) {
            entityManager.createNativeQuery(
                    "DELETE FROM room_shared_facilities WHERE room_id IN (:rids)")
                .setParameter("rids", allRoomIds)
                .executeUpdate();
        }

        // Bước 2: Ghi lại liên kết mới theo phân công hiện tại.
        if (facilities == null || facilities.isEmpty()) return;
        for (com.stayhub.api.entity.SharedFacility f : facilities) {
            if (f == null || f.getId() == null) continue;
            java.util.List<Long> linkedRoomIds =
                byFacility.getOrDefault(f.getId(), java.util.Collections.emptyList());

            for (Long roomId : linkedRoomIds) {
                if (roomId == null) continue;
                entityManager.createNativeQuery(
                        "INSERT INTO room_shared_facilities (facility_id, room_id) "
                            + "VALUES (:fid, :rid)")
                    .setParameter("fid", f.getId())
                    .setParameter("rid", roomId)
                    .executeUpdate();
            }
        }
    }

    /**
     * Chuyển ảnh base64 (do RoomConfigBottomSheet gửi lên) thành URL cloud.
     *
     * <p>Hỗ trợ hai dạng payload:</p>
     * <ul>
     *   <li>{@code List<String>} — dùng cho {@code photos}.</li>
     *   <li>{@code Map<String, Object>} — dùng cho {@code featurePhotos}
     *       (mỗi key là tên khu vực, value là danh sách ảnh).</li>
     * </ul>
     *
     * <p>Chuỗi đã là URL ({@code http...}) được giữ nguyên; chuỗi rỗng bị bỏ.
     * Nếu upload thất bại (trả null) thì bỏ ảnh đó thay vì lưu base64 thô,
     * tránh làm phình cột jsonb {@code detailed_info} và {@code description}.</p>
     */
    private Object uploadBase64Images(Object value) {
        if (value instanceof java.util.List) {
            java.util.List<String> out = new java.util.ArrayList<>();
            for (Object o : (java.util.List<?>) value) {
                if (o == null) continue;
                String s = o.toString();
                if (s.isBlank()) continue;
                if (s.startsWith("http")) {
                    out.add(s);
                    continue;
                }
                String url = cloudStorageService.uploadBase64(s);
                if (url != null) out.add(url);
            }
            return out;
        } else if (value instanceof java.util.Map) {
            java.util.Map<String, Object> out = new java.util.HashMap<>();
            for (java.util.Map.Entry<?, ?> e : ((java.util.Map<?, ?>) value).entrySet()) {
                out.put(String.valueOf(e.getKey()), uploadBase64Images(e.getValue()));
            }
            return out;
        }
        return value;
    }

    /**
     * Đọc danh sách tiện ích ({@code branchAmenities}) trong JSON mô tả cấu trúc
     * và gán giá tương ứng vào các cột phí của chi nhánh.
     *
     * <p>Frontend lưu giá thật của Wifi / Gửi xe / Rác trong phần tử tiện ích
     * (kèm {@code chargeType}); các cột {@code internet_fee}, {@code parking_fee},
     * {@code garbage_fee} trước đây không được suy ra từ đó nên luôn bằng 0 ⇒
     * chi tiết phòng hiển thị "Miễn phí" dù chủ nhà đã nhập giá.</p>
     *
     * <p>Chỉ ghi đè khi tìm thấy tiện ích khớp và giá > 0, để không xoá giá
     * đã lưu khi payload không chứa tiện ích tương ứng.</p>
     */
    private void applyAmenityFees(Branch branch, com.fasterxml.jackson.databind.JsonNode meta) {
        if (meta == null || !meta.has("branchAmenities")) return;
        com.fasterxml.jackson.databind.JsonNode amenities = meta.get("branchAmenities");
        if (amenities == null || !amenities.isArray()) return;

        double internet = 0.0, parking = 0.0, garbage = 0.0, service = 0.0;
        for (com.fasterxml.jackson.databind.JsonNode a : amenities) {
            String name = a.has("name") ? a.get("name").asText("") : "";
            if (name == null || name.trim().isEmpty()) continue;
            String lower = name.toLowerCase();

            // Tôn trọng `chargeType`: tiện ích "free" luôn miễn phí, kể cả khi
            // payload còn sót `price` > 0 (tránh hiển thị giá sai).
            String chargeType = a.has("chargeType") ? a.get("chargeType").asText("free") : "free";
            if ("free".equalsIgnoreCase(chargeType)) continue;

            double price = a.has("price") ? a.get("price").asDouble(0.0) : 0.0;
            if (price <= 0) continue;

            if (lower.contains("wifi") || lower.contains("internet") || lower.contains("mạng")) {
                if (price > internet) internet = price;
            } else if (lower.contains("bãi để xe") || lower.contains("giữ xe")
                    || lower.contains("gửi xe") || lower.contains("đỗ xe")) {
                if (price > parking) parking = price;
            } else if (lower.contains("vệ sinh") || lower.contains("rác")
                    || lower.contains("thu gom")) {
                if (price > garbage) garbage = price;
            } else if (lower.contains("dịch vụ") || lower.contains("bảo vệ")
                    || lower.contains("thang máy") || lower.contains("điện")
                    || lower.contains("nước") || lower.contains("quản lý")) {
                // Các tiện ích thu phí khác (bảo vệ, thang máy, quản lý…) được
                // gộp vào phí dịch vụ chung để không hiển thị "Miễn phí" sai.
                if (price > service) service = price;
            }
        }

        if (internet > 0) branch.setInternetFee(internet);
        if (parking > 0) branch.setParkingFee(parking);
        if (garbage > 0) branch.setGarbageFee(garbage);
        if (service > 0 && (branch.getServiceFee() == null || branch.getServiceFee() <= 0)) {
            branch.setServiceFee(service);
        }
    }

    private double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        lat1 = Math.toRadians(lat1);
        lat2 = Math.toRadians(lat2);
        double a = Math.pow(Math.sin(dLat / 2), 2)
                 + Math.cos(lat1) * Math.cos(lat2)
                 * Math.pow(Math.sin(dLon / 2), 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return EARTH_RADIUS_KM * c;
    }

    @org.springframework.scheduling.annotation.Scheduled(cron = "0 0 2 * * ?")
    @org.springframework.transaction.annotation.Transactional
    public void cleanupOldDraftBranches() {
        java.time.LocalDateTime cutoff = java.time.LocalDateTime.now().minusHours(24);
        List<Branch> oldDrafts = branchRepository.findOldDraftBranches(cutoff);
        if (!oldDrafts.isEmpty()) {
            System.out.println(">>> [CronJob] Cleaning up " + oldDrafts.size() + " old DRAFT branches...");
            branchRepository.deleteAll(oldDrafts);
        }
    }
}
