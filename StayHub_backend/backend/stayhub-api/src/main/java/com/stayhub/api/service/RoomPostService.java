package com.stayhub.api.service;

import com.stayhub.api.dto.RoomPostDTO;
import com.stayhub.api.entity.Branch;
import com.stayhub.api.entity.Room;
import com.stayhub.api.entity.RoomPost;
import com.stayhub.api.entity.RoomStatus;
import com.stayhub.api.repository.BranchRepository;
import com.stayhub.api.repository.RoomPostRepository;
import com.stayhub.api.repository.VoucherRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.repository.WishlistRepository;
import com.stayhub.api.repository.VoucherRoomRepository;
import com.stayhub.api.entity.User;
import com.stayhub.api.entity.VoucherRoom;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoomPostService {

    private final RoomPostRepository roomPostRepository;
    private final RoomRepository roomRepository;
    private final BranchRepository branchRepository;
    private final UserRepository userRepository;
    private final VoucherRepository voucherRepository;
    private final WishlistRepository wishlistRepository;
    private final VoucherRoomRepository voucherRoomRepository;

    @Transactional
    public RoomPostDTO savePost(Long ownerId, Long roomId, RoomPostDTO request) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy phòng"));

        if (!room.getOwnerId().equals(ownerId)) {
            throw new RuntimeException("Không có quyền thao tác trên phòng này");
        }

        // BUGFIX (logic/data): trước đây chỉ chặn BAO_TRI, nên owner vẫn tạo
        // được tin ACTIVE cho phòng DA_THUE/DONG_CUA/CHO_KICH_HOAT — nhưng
        // search & feed công khai chỉ hiển thị phòng TRONG/SAP_TRONG, khiến
        // tin đó "đăng xong nhưng vĩnh viễn không ai thấy" (silent failure).
        // Chỉ cho đăng khi phòng ở trạng thái có thể cho thuê.
        if (room.getStatus() != RoomStatus.TRONG
                && room.getStatus() != RoomStatus.SAP_TRONG) {
            throw new RuntimeException(
                    "Chỉ có thể đăng tin cho phòng đang trống hoặc sắp trống");
        }

        Optional<RoomPost> existingPostOpt = roomPostRepository.findByRoomId(roomId);
        RoomPost post;

        if (existingPostOpt.isPresent()) {
            post = existingPostOpt.get();
            post.setPostTitle(request.getPostTitle());
            post.setPostDescription(request.getPostDescription());
            post.setCoverImageUrl(request.getCoverImageUrl());
            post.setPostImages(request.getPostImages());
            post.setRentingPrice(request.getRentingPrice());
            post.setDeposit(request.getDeposit());
            post.setHasPromotion(request.getHasPromotion() != null ? request.getHasPromotion() : false);
            post.setDiscountType(request.getDiscountType());
            post.setDiscountAmount(request.getDiscountAmount());
            post.setPromotionMonths(request.getPromotionMonths());
            post.setPromotionDescription(request.getPromotionDescription());
            post.setStatus(request.getStatus() != null ? request.getStatus() : "ACTIVE");
        } else {
            post = RoomPost.builder()
                    .roomId(roomId)
                    .ownerId(ownerId)
                    .postTitle(request.getPostTitle())
                    .postDescription(request.getPostDescription())
                    .coverImageUrl(request.getCoverImageUrl())
                    .postImages(request.getPostImages())
                    .rentingPrice(request.getRentingPrice())
                    .deposit(request.getDeposit())
                    .hasPromotion(request.getHasPromotion() != null ? request.getHasPromotion() : false)
                    .discountType(request.getDiscountType())
                    .discountAmount(request.getDiscountAmount())
                    .promotionMonths(request.getPromotionMonths())
                    .promotionDescription(request.getPromotionDescription())
                    .status(request.getStatus() != null ? request.getStatus() : "ACTIVE")
                    .build();
        }

        RoomPost savedPost = roomPostRepository.save(post);
        
        // Cập nhật lại mô tả của phòng bằng mô tả bài đăng để đồng nhất (1 phòng chỉ có 1 mô tả)
        if (request.getPostDescription() != null) {
            room.setDescription(request.getPostDescription());
            roomRepository.save(room);
        }
        
        return mapToDTO(savedPost);
    }

    @Transactional
    public void autoPublishPostIfEmpty(Room room) {
        if (room.getStatus() != RoomStatus.TRONG) {
            return;
        }

        // Tự động đẩy bài lên sàn khi phòng TRỐNG và có mô tả/ảnh
        Optional<RoomPost> existingPostOpt = roomPostRepository.findByRoomId(room.getId());
        RoomPost post;

        if (existingPostOpt.isPresent()) {
            post = existingPostOpt.get();
            // Lấy tiêu đề tự sinh thay vì tên phòng (tránh lộ tên nhạy cảm)
            // CHỈ GHI ĐÈ nếu tiêu đề đang trống, hoặc đang bị dính lỗi cũ (tiêu đề = tên phòng)
            if (post.getPostTitle() == null || post.getPostTitle().trim().isEmpty() || post.getPostTitle().equals(room.getRoomName())) {
                post.setPostTitle(generatePostTitle(room));
            }
            
            String desc = room.getDescription();
            if (desc == null || desc.trim().isEmpty()) {
                desc = generatePostDescription(room);
                room.setDescription(desc);
                roomRepository.save(room);
            }
            // Mặc dù source of truth là room, ta có thể sync tạm vào post nếu cần thiết
            // (Hiện tại mapToDTO đã luôn ưu tiên đọc từ roomRepository)
            post.setPostDescription(desc);
            
            post.setRentingPrice(room.getPrice());
            post.setDeposit(room.getDeposit());
            post.setStatus("ACTIVE");
            // Ảnh được giữ nguyên nếu đã có, hoặc lấy từ room
            if (post.getCoverImageUrl() == null || post.getCoverImageUrl().isEmpty()) {
                // Extract first image from room
                if (room.getRoomImages() != null && room.getRoomImages().contains("[")) {
                    try {
                        com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                        java.util.List<String> images = mapper.readValue(room.getRoomImages(), java.util.List.class);
                        if (images != null && !images.isEmpty()) {
                            post.setCoverImageUrl(images.get(0));
                            post.setPostImages(room.getRoomImages());
                        }
                    } catch (Exception e) {}
                }
            }
        } else {
            String coverImage = "";
            String postImagesStr = room.getRoomImages();
            if (postImagesStr != null && postImagesStr.contains("[")) {
                try {
                    com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                    java.util.List<String> images = mapper.readValue(postImagesStr, java.util.List.class);
                    if (images != null && !images.isEmpty()) {
                        coverImage = images.get(0);
                    }
                } catch (Exception e) {}
            }
            
            String desc = room.getDescription();
            if (desc == null || desc.trim().isEmpty()) {
                desc = generatePostDescription(room);
                room.setDescription(desc); // Lưu lại mô tả tự sinh vào phòng
                roomRepository.save(room);
            }
            
            post = RoomPost.builder()
                    .roomId(room.getId())
                    .ownerId(room.getOwnerId())
                    .postTitle(generatePostTitle(room))
                    .postDescription(desc)
                    .coverImageUrl(coverImage)
                    .postImages(postImagesStr)
                    .rentingPrice(room.getPrice())
                    .deposit(room.getDeposit())
                    .hasPromotion(false)
                    .status("ACTIVE")
                    .build();
        }

        roomPostRepository.save(post);
    }

    private String generatePostTitle(Room room) {
        String baseType = "Cho thuê phòng";
        if (room.getRoomSubType() != null) {
            switch (room.getRoomSubType()) {
                case "PHONG_TRO": baseType = "Cho thuê phòng trọ"; break;
                case "CHUNG_CU_MINI": baseType = "Cho thuê chung cư mini"; break;
                case "NHA_NGUYEN_CAN": baseType = "Cho thuê nhà nguyên căn"; break;
                case "CHUNG_CU": baseType = "Cho thuê căn hộ chung cư"; break;
                case "SLEEPBOX": baseType = "Cho thuê Sleepbox"; break;
                case "O_GHEP_KTX": baseType = "Cho thuê chỗ ở ghép/KTX"; break;
                case "KIOT": baseType = "Cho thuê Kiot/Mặt bằng"; break;
                case "OFFICE": baseType = "Cho thuê văn phòng"; break;
            }
        }
        
        if (room.getBranchId() != null) {
            Optional<Branch> branchOpt = branchRepository.findById(room.getBranchId());
            if (branchOpt.isPresent()) {
                Branch b = branchOpt.get();
                String addr = b.getAddress() != null ? b.getAddress() : "";
                if (!addr.isEmpty()) {
                    return baseType + " tiện nghi tại " + addr;
                }
            }
        }
        
        return baseType + " đầy đủ tiện nghi, giá tốt";
    }

    private String generatePostDescription(Room room) {
        StringBuilder sb = new StringBuilder();
        sb.append("🔥 Cho thuê phòng trống sẵn sàng dọn vào ở ngay!\n\n");
        if (room.getPrice() != null) {
            java.text.NumberFormat fmt = java.text.NumberFormat.getNumberInstance(new java.util.Locale("vi", "VN"));
            sb.append("💰 Giá thuê: ").append(fmt.format(room.getPrice().longValue())).append("đ/tháng\n");
        }
        if (room.getFloorArea() != null) {
            sb.append("📐 Diện tích: ").append(room.getFloorArea()).append("m2\n");
        }
        
        java.util.Map<String, Object> info = room.getDetailedInfo();
        if (info != null) {
            boolean hasBalcony = Boolean.TRUE.equals(info.get("hasBalcony"));
            boolean hasWindow = Boolean.TRUE.equals(info.get("hasWindow"));
            boolean hasKitchen = Boolean.TRUE.equals(info.get("hasKitchen"));
            
            java.util.List<String> features = new java.util.ArrayList<>();
            if (hasBalcony) features.add("ban công thoáng mát");
            if (hasWindow) features.add("cửa sổ đón nắng");
            if (hasKitchen) features.add("kệ bếp nấu ăn");
            
            if (!features.isEmpty()) {
                sb.append("✨ Phòng có ").append(String.join(", ", features)).append(".\n");
            }
        }
        sb.append("An ninh đảm bảo, giờ giấc tự do, chủ nhà thân thiện. Liên hệ ngay để xem phòng thực tế!");
        return sb.toString();
    }

    public RoomPostDTO getPostByRoomId(Long roomId) {
        return roomPostRepository.findByRoomId(roomId)
                .map(this::mapToDTO)
                .orElse(null);
    }

    public java.util.List<RoomPostDTO> getPostsByOwner(Long ownerId) {
        return roomPostRepository.findByOwnerId(ownerId).stream()
                .map(this::mapToDTO)
                .toList();
    }

    public org.springframework.data.domain.Page<com.stayhub.api.dto.MarketplacePostDTO> getPublicPosts(org.springframework.data.domain.Pageable pageable) {
        org.springframework.data.domain.Page<RoomPost> activePostsPage = roomPostRepository.findActivePublicPosts(pageable);

        List<RoomPost> activePosts = activePostsPage.getContent();
        return mapPostsToPage(activePostsPage, activePosts);
    }

    /**
     * Chi tiết một tin đăng công khai.
     *
     * <p><b>BUGFIX (không xem được chi tiết phòng):</b> endpoint
     * {@code GET /v1/rooms/public/{id}} trước đây CHỈ tra theo {@code postId}
     * (khoá của bảng {@code room_posts}). Nhưng feed/search trả về DTO có
     * {@code id = roomId} (khoá bảng {@code rooms}) — frontend lại truyền chính
     * {@code id} đó vào URL, nên backend đi tìm post theo roomId → luôn 404
     * ("Không tìm thấy tin đăng") → màn chi tiết phòng trắng/lỗi 100%.</p>
     *
     * <p>Nay tra <b>kép</b>: thử {@code postId} trước (đúng ngữ nghĩa cũ), nếu
     * không có thì fallback sang {@code roomId} (tương thích với mọi call-site
     * đang truyền roomId). Nhờ vậy cả hai loại ID đều mở được chi tiết — đúng
     * nguyên tắc "định danh theo ID, không đoán theo chữ".</p>
     */
    public com.stayhub.api.dto.MarketplacePostDTO getPostDetail(Long id) {
        // 1) Ưu tiên tra theo postId (giữ nguyên hành vi/ngữ nghĩa cũ).
        RoomPost post = roomPostRepository.findById(id).orElse(null);

        // 2) Fallback: coi `id` là roomId → tra tin đăng đang hoạt động của phòng.
        if (post == null) {
            post = roomPostRepository.findByRoomId(id).orElse(null);
        }

        if (post == null) {
            throw new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy tin đăng");
        }

        Room room = roomRepository.findById(post.getRoomId())
                .orElseThrow(() -> new com.stayhub.api.exception.ResourceNotFoundException("Không tìm thấy phòng"));
        
        Branch branch = null;
        if (room.getBranchId() != null) {
            branch = branchRepository.findById(room.getBranchId()).orElse(null);
        }
        User owner = userRepository.findById(room.getOwnerId()).orElse(null);
        
        int wishlistCount = (int) wishlistRepository.countByRoomId(room.getId());
        java.util.List<com.stayhub.api.entity.Voucher> vouchers = voucherRepository.findApplicableVouchers(room.getId(), room.getBranchId());
        com.stayhub.api.entity.Voucher promo = null;
        double maxDiscount = -1;
        double price = room.getPrice() != null ? room.getPrice() : 0;
        for (com.stayhub.api.entity.Voucher v : vouchers) {
            double discounted = v.computeDiscountedPrice(price);
            double discount = price - discounted;
            if (discount > maxDiscount) {
                maxDiscount = discount;
                promo = v;
            }
        }
        
        Map<Long, Branch> branchMap = branch != null ? Map.of(branch.getId(), branch) : java.util.Collections.emptyMap();
        Map<Long, User> ownerMap = owner != null ? Map.of(owner.getId(), owner) : java.util.Collections.emptyMap();
        
        return mapRoomToDTO(room, post, promo, wishlistCount, branchMap, ownerMap);
    }

    /**
     * Tìm kiếm phòng công khai theo tiêu chí đầy đủ (giá, diện tích, loại phòng,
     * tiện ích, hướng, tỉnh/thành, vị trí, sắp xếp...).
     *
     * <p>Đây là entry-point chính cho tính năng "Tìm phòng + Bộ lọc" của guest.
     * Toàn bộ lọc chạy ở tầng DB (specification) nên phân trang luôn chính xác —
     * khác với cách lọc client-side trước đây vốn chỉ lọc trên trang hiện tại.</p>
     */
    public org.springframework.data.domain.Page<com.stayhub.api.dto.MarketplacePostDTO> searchPublicPosts(
            com.stayhub.api.dto.request.RoomSearchCriteria criteria,
            org.springframework.data.domain.Pageable pageable
    ) {
        org.springframework.data.jpa.domain.Specification<RoomPost> spec =
                com.stayhub.api.repository.RoomPostSpecification.fromCriteria(criteria);
        org.springframework.data.domain.Page<RoomPost> searchPage =
                roomPostRepository.findAll(spec, pageable);
        return mapPostsToPage(searchPage, searchPage.getContent());
    }

    /**
     * Giữ lại chữ ký cũ (8 tham số) để không phá vỡ call-site hiện có.
     *
     * @deprecated dùng {@link #searchPublicPosts(RoomSearchCriteria, Pageable)}.
     */
    @Deprecated
    public org.springframework.data.domain.Page<com.stayhub.api.dto.MarketplacePostDTO> searchPublicPosts(
            Double minPrice,
            Double maxPrice,
            java.util.List<String> roomTypes,
            Integer bedrooms,
            String keyword,
            Double lat,
            Double lng,
            Double radius,
            org.springframework.data.domain.Pageable pageable
    ) {
        return searchPublicPosts(com.stayhub.api.dto.request.RoomSearchCriteria.builder()
                .minPrice(minPrice)
                .maxPrice(maxPrice)
                .roomTypes(roomTypes)
                .bedrooms(bedrooms)
                .keyword(keyword)
                .lat(lat)
                .lng(lng)
                .radius(radius)
                .build(), pageable);
    }

    /**
     * Metadata cho bộ lọc: khoảng giá / diện tích thực tế trong DB, danh sách
     * loại phòng và tiện ích đang có. Frontend dùng để dựng slider + chip động
     * thay vì hard-code, đảm bảo bộ lọc luôn khớp dữ liệu thật.
     */
    public java.util.Map<String, Object> getFilterMetadata() {
        java.util.Map<String, Object> meta = new java.util.LinkedHashMap<>();

        // Chỉ lấy (roomId, rentingPrice) của tin ACTIVE bằng 1 query projection
        // nhẹ rồi nạp phòng theo lô — tránh N+1 và tránh kéo cả entity RoomPost
        // nặng vào bộ nhớ (trước đây dùng findAll(spec) gây nguy cơ OOM).
        java.util.List<Object[]> activePostPairs =
                roomPostRepository.findActivePostRoomPricePairs();

        java.util.Map<Long, Double> postPriceByRoom = new java.util.HashMap<>();
        java.util.Set<Long> roomIds = new java.util.LinkedHashSet<>();
        int activePostCount = 0;
        for (Object[] pair : activePostPairs) {
            if (pair == null || pair.length < 2) continue;
            Long roomId = (Long) pair[0];
            if (roomId == null) continue;
            activePostCount++;
            roomIds.add(roomId);
            if (pair[1] instanceof Number) {
                postPriceByRoom.put(roomId, ((Number) pair[1]).doubleValue());
            }
        }

        java.util.List<Room> rooms = roomIds.isEmpty()
                ? java.util.List.of()
                : roomRepository.findAllById(roomIds);

        double minPrice = Double.MAX_VALUE, maxPrice = 0;
        double minArea = Double.MAX_VALUE, maxArea = 0;
        java.util.Set<String> roomTypes = new java.util.TreeSet<>();
        java.util.Set<String> amenities = new java.util.TreeSet<>();
        java.util.Set<String> directions = new java.util.TreeSet<>();
        java.util.Set<String> provinces = new java.util.TreeSet<>();
        java.util.Set<Integer> bedroomCounts = new java.util.TreeSet<>();

        for (Room room : rooms) {
            if (room == null) continue;

            Double price = postPriceByRoom.getOrDefault(room.getId(), room.getPrice());
            if (price != null && price > 0) {
                minPrice = Math.min(minPrice, price);
                maxPrice = Math.max(maxPrice, price);
            }
            if (room.getFloorArea() != null && room.getFloorArea() > 0) {
                minArea = Math.min(minArea, room.getFloorArea());
                maxArea = Math.max(maxArea, room.getFloorArea());
            }
            // Chuẩn hoá về MÃ canonical để chip bộ lọc luôn gửi đúng id-mô-hình
            // (dữ liệu cũ có thể còn alias như PHONG_THUONG).
            // EDGE CASE: nếu phòng chưa có loại (NULL) hoặc loại lạ, KHÔNG được
            // âm thầm bỏ qua — nếu bỏ qua thì phòng đó vĩnh viễn không xuất hiện
            // trong danh sách chip, guest không cách nào lọc tới. Gom vào bucket
            // "KHAC" để vẫn hiển thị được và đếm được.
            String canonicalType =
                    com.stayhub.api.util.RoomTypeCodes.toCode(room.getRoomSubType());
            if (canonicalType == null && room.getDetailedInfo() != null) {
                Object diType = room.getDetailedInfo().get("roomType");
                if (diType != null) {
                    canonicalType = com.stayhub.api.util.RoomTypeCodes.toCode(diType.toString());
                }
            }
            roomTypes.add(canonicalType != null ? canonicalType : "KHAC");
            if (room.getDirection() != null && !room.getDirection().isBlank()) {
                directions.add(room.getDirection().toUpperCase());
            }
            if (room.getBedrooms() != null && room.getBedrooms() > 0) {
                bedroomCounts.add(room.getBedrooms());
            }
            String province = extractProvince(room.getAddress(), room.getAddressOld());
            if (province != null) provinces.add(province);
            amenities.addAll(parseFurnitureCodes(room.getFurniture()));
        }

        meta.put("minPrice", minPrice == Double.MAX_VALUE ? 0 : minPrice);
        meta.put("maxPrice", maxPrice == 0 ? 50000000 : maxPrice);
        meta.put("minArea", minArea == Double.MAX_VALUE ? 0 : minArea);
        meta.put("maxArea", maxArea == 0 ? 200 : maxArea);
        meta.put("roomTypes", new java.util.ArrayList<>(roomTypes));
        meta.put("amenities", new java.util.ArrayList<>(amenities));
        meta.put("directions", new java.util.ArrayList<>(directions));
        meta.put("provinces", new java.util.ArrayList<>(provinces));
        meta.put("bedrooms", new java.util.ArrayList<>(bedroomCounts));
        meta.put("totalActivePosts", activePostCount);
        return meta;
    }

    /**
     * Trích tỉnh/thành từ địa chỉ (mới hoặc cũ).
     *
     * <p>Địa chỉ Việt Nam thường có dạng {@code "..., Quận X, TP. Hồ Chí Minh"}
     * hoặc {@code "..., Huyện Y, Tỉnh Bình Dương"}. Ta lấy token cuối cùng sau
     * dấu phẩy và chuẩn hoá bỏ tiền tố {@code TP.}/{@code Tỉnh}/{@code Thành phố}.</p>
     *
     * @return tên tỉnh/thành đã chuẩn hoá, hoặc {@code null} nếu không suy ra được.
     */
    private String extractProvince(String address, String addressOld) {
        String src = (address != null && !address.isBlank()) ? address : addressOld;
        if (src == null || src.isBlank()) return null;
        String[] parts = src.split(",");
        String last = parts[parts.length - 1].trim();
        if (last.isEmpty()) return null;
        // Bỏ tiền tố hành chính để gom nhóm nhất quán.
        String cleaned = last.replaceAll(
                "(?i)^(tp\\.?|thành phố|tỉnh|t\\.?)\\s*", "").trim();
        return cleaned.isEmpty() ? null : cleaned;
    }

    /**
     * Trích mã tiện ích từ cột TEXT {@code furniture}.
     *
     * <p>Chịu được cả 2 định dạng: JSON array ({@code ["AC","WIFI"]}) và CSV
     * ({@code AC,WIFI}) — dữ liệu nhập tay trong DB không đồng nhất.</p>
     */
    private java.util.Set<String> parseFurnitureCodes(String furniture) {
        java.util.Set<String> codes = new java.util.LinkedHashSet<>();
        if (furniture == null || furniture.isBlank()) return codes;
        String cleaned = furniture.replaceAll("[\\[\\]{}\"]", " ");
        for (String token : cleaned.split("[,;]")) {
            String t = token.trim();
            if (!t.isEmpty()) codes.add(t.toUpperCase());
        }
        return codes;
    }

    private org.springframework.data.domain.Page<com.stayhub.api.dto.MarketplacePostDTO> mapPostsToPage(
            org.springframework.data.domain.Page<RoomPost> activePostsPage,
            List<RoomPost> activePosts
    ) {
        if (activePosts.isEmpty()) {
            return activePostsPage.map(post -> new com.stayhub.api.dto.MarketplacePostDTO());
        }

        // BUGFIX: lọc null trước khi đưa vào các truy vấn `IN (...)`. Trước đây
        // roomId null lọt vào findAllById / countWishlistsByRoomIdIn /
        // findApplicableVouchersBatch → sinh `IN (null)` khiến JPQL trả kết quả
        // sai hoặc ném lỗi, làm hỏng cả trang marketplace.
        List<Long> roomIds = activePosts.stream()
                .map(RoomPost::getRoomId)
                .filter(java.util.Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, Room> roomMap = roomIds.isEmpty()
                ? java.util.Collections.emptyMap()
                : roomRepository.findAllById(roomIds).stream()
                        .collect(Collectors.toMap(Room::getId, r -> r));

        List<Long> branchIds = roomMap.values().stream()
                .map(Room::getBranchId)
                .filter(java.util.Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());

        // ── Batch-load branches (tránh N+1: trước đây mỗi phòng gọi findById) ──
        Map<Long, Branch> branchMap = branchIds.isEmpty()
                ? java.util.Collections.emptyMap()
                : branchRepository.findAllById(branchIds).stream()
                        .collect(Collectors.toMap(Branch::getId, b -> b));

        // ── Batch-load owners (tránh N+1 tương tự cho userRepository) ─────────
        List<Long> ownerIds = roomMap.values().stream()
                .map(Room::getOwnerId)
                .filter(java.util.Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, User> ownerMap = ownerIds.isEmpty()
                ? java.util.Collections.emptyMap()
                : userRepository.findAllById(ownerIds).stream()
                        .collect(Collectors.toMap(User::getId, u -> u));

        // Batch queries
        List<Object[]> wishlistCounts = wishlistRepository.countWishlistsByRoomIdIn(roomIds);
        Map<Long, Integer> wishlistCountMap = new java.util.HashMap<>();
        for (Object[] row : wishlistCounts) {
            wishlistCountMap.put((Long) row[0], ((Number) row[1]).intValue());
        }

        List<com.stayhub.api.entity.Voucher> allApplicableVouchers = voucherRepository.findApplicableVouchersBatch(roomIds, branchIds);
        List<VoucherRoom> voucherRooms = voucherRoomRepository.findByRoomIdIn(roomIds);

        // Map voucher ID -> list of room IDs it applies to explicitly via VoucherRoom
        Map<Long, List<Long>> voucherRoomMappings = new java.util.HashMap<>();
        for (VoucherRoom vr : voucherRooms) {
            voucherRoomMappings.computeIfAbsent(vr.getVoucherId(), k -> new java.util.ArrayList<>()).add(vr.getRoomId());
        }

        java.util.List<com.stayhub.api.dto.MarketplacePostDTO> dtos = new java.util.ArrayList<>();
        for (RoomPost post : activePosts) {
            Room room = roomMap.get(post.getRoomId());
            // BUGFIX: trước đây `if (room != null)` âm thầm BỎ QUA bài đăng khi
            // room không load được (bị xoá mềm / race condition) → trang trả về
            // ít item hơn `totalElements` gây phân trang sai và "mất phòng".
            // Nay vẫn tạo DTO tối thiểu từ chính RoomPost để không mất dữ liệu.
            if (room == null) {
                com.stayhub.api.dto.MarketplacePostDTO orphan = new com.stayhub.api.dto.MarketplacePostDTO();
                orphan.setId(post.getRoomId());
                orphan.setOwnerId(post.getOwnerId());
                orphan.setPostId(post.getId());
                orphan.setPostTitle(post.getPostTitle());
                orphan.setDescription(post.getPostDescription());
                orphan.setCoverImageUrl(post.getCoverImageUrl());
                orphan.setPostImages(post.getPostImages());
                orphan.setPrice(post.getRentingPrice());
                orphan.setDeposit(post.getDeposit());
                orphan.setPostStatus(post.getStatus());
                orphan.setPostCreatedAt(post.getCreatedAt());
                orphan.setHasPromotion(post.getHasPromotion());
                orphan.setWishlistCount(wishlistCountMap.getOrDefault(post.getRoomId(), 0));
                dtos.add(orphan);
                continue;
            }
            {
                int wCount = wishlistCountMap.getOrDefault(room.getId(), 0);

                // Lọc voucher phù hợp cho phòng này từ danh sách batch
                com.stayhub.api.entity.Voucher bestVoucher = null;
                double maxDiscount = -1;
                double price = room.getPrice() != null ? room.getPrice() : 0;

                for (com.stayhub.api.entity.Voucher v : allApplicableVouchers) {
                    boolean isApplicable = false;
                    if (Boolean.TRUE.equals(v.getApplyAllRooms())) {
                        isApplicable = true;
                    } else if (v.getBranchId() != null && v.getBranchId().equals(room.getBranchId())) {
                        isApplicable = true;
                    } else {
                        List<Long> specificRoomIds = voucherRoomMappings.get(v.getId());
                        if (specificRoomIds != null && specificRoomIds.contains(room.getId())) {
                            isApplicable = true;
                        }
                    }

                    if (isApplicable) {
                        double discounted = v.computeDiscountedPrice(price);
                        double discount = price - discounted;
                        if (discount > maxDiscount) {
                            maxDiscount = discount;
                            bestVoucher = v;
                        }
                    }
                }

                dtos.add(mapRoomToDTO(room, post, bestVoucher, wCount, branchMap, ownerMap));
            }
        }

        // Return a new PageImpl with the mapped DTOs, keeping the original pageable and total elements
        return new org.springframework.data.domain.PageImpl<>(dtos, activePostsPage.getPageable(), activePostsPage.getTotalElements());
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private com.stayhub.api.dto.MarketplacePostDTO mapRoomToDTO(
            Room room, RoomPost post, com.stayhub.api.entity.Voucher promo, int wishlistCount,
            Map<Long, Branch> branchMap, Map<Long, User> ownerMap) {

        com.stayhub.api.dto.MarketplacePostDTO dto = new com.stayhub.api.dto.MarketplacePostDTO();

        // Core
        dto.setId(room.getId());
        dto.setOwnerId(room.getOwnerId());
        dto.setBranchId(room.getBranchId());
        dto.setRoomName(room.getRoomName());
        dto.setPrice(room.getPrice());
        dto.setAddress(room.getAddress());
        dto.setStatus(room.getStatus().name());
        dto.setDescription(room.getDescription());
        dto.setFloorArea(room.getFloorArea());
        dto.setArea(room.getFloorArea()); // alias cho frontend
        dto.setFurniture(room.getFurniture());
        dto.setVideoUrl(room.getVideoUrl());
        dto.setPois(room.getPois());
        dto.setLatitude(room.getLatitude());
        dto.setLongitude(room.getLongitude());
        dto.setMaxGuests(room.getMaxGuests());
        dto.setBedrooms(room.getBedrooms());
        dto.setBeds(room.getBeds());
        dto.setBathrooms(room.getBathrooms());
        dto.setElectricityPrice(room.getElectricityPrice());
        dto.setWaterPrice(room.getWaterPrice());
        dto.setServiceFee(room.getServiceFee());
        dto.setHasBalcony(room.getHasBalcony());
        dto.setHasWindow(room.getHasWindow());

        // Room detail fields
        dto.setFloor(room.getFloor());
        dto.setDirection(room.getDirection());
        dto.setBathroomType(room.getBathroomType());
        dto.setDeposit(room.getDeposit() != null ? room.getDeposit() : room.getBaseDeposit());
        dto.setRoomCode(room.getRoomCode());

        // ── Ảnh phòng + địa chỉ cũ (trước đây bị bỏ quên → gallery/địa chỉ lệch) ─
        dto.setRoomImages(room.getRoomImages());
        dto.setAddressOld(room.getAddressOld());
        
        if (branchMap != null && room.getBranchId() != null && branchMap.containsKey(room.getBranchId())) {
            Branch b = branchMap.get(room.getBranchId());
            dto.setBranchAmenities(parseBranchAmenities(b.getAmenities()));

            // ── Kế thừa toạ độ và địa chỉ từ Chi nhánh nếu phòng chưa set riêng ──
            if (dto.getLatitude() == null && b.getLatitude() != null) {
                dto.setLatitude(b.getLatitude());
            }
            if (dto.getLongitude() == null && b.getLongitude() != null) {
                dto.setLongitude(b.getLongitude());
            }
            if ((dto.getAddress() == null || dto.getAddress().isBlank()) && b.getAddress() != null) {
                dto.setAddress(b.getAddress());
            }
            if ((dto.getAddressOld() == null || dto.getAddressOld().isBlank()) && b.getAddressOld() != null) {
                dto.setAddressOld(b.getAddressOld());
            }
        }

        // ── Cấu hình phòng bước 2/3 (wizard) ──────────────────────────────────
        dto.setMezzanineArea(room.getMezzanineArea());
        dto.setMaxVehicles(room.getMaxVehicles());
        dto.setAvailableFrom(room.getAvailableFrom());
        // Loại phòng: ưu tiên cột canonical `room_sub_type`; nếu NULL (dữ liệu cũ
        // tạo trước khi đồng bộ) thì fallback sang `detailed_info.roomType` rồi
        // chuẩn hoá về MÃ canonical. Luôn trả MÃ, không trả nhãn.
        String resolvedRoomType = com.stayhub.api.util.RoomTypeCodes.toCode(room.getRoomSubType());
        if (resolvedRoomType == null && room.getDetailedInfo() != null) {
            Object diType = room.getDetailedInfo().get("roomType");
            if (diType != null) {
                resolvedRoomType = com.stayhub.api.util.RoomTypeCodes.toCode(diType.toString());
            }
        }
        dto.setRoomSubType(resolvedRoomType);
        dto.setRoomType(resolvedRoomType);
        dto.setIsSharedWc(room.getIsSharedWc());
        dto.setSharedWcId(room.getSharedWcId());
        dto.setOldElectricityIndex(room.getOldElectricityIndex());
        dto.setOldWaterIndex(room.getOldWaterIndex());
        dto.setHasPrivateElectricMeter(room.getHasPrivateElectricMeter());
        dto.setHasPrivateWaterMeter(room.getHasPrivateWaterMeter());
        dto.setElectricityPricingType(
                room.getElectricityPricingType() != null ? room.getElectricityPricingType().name() : null);
        dto.setServiceFeePricingType(
                room.getServiceFeePricingType() != null ? room.getServiceFeePricingType().name() : null);

        // ── Ghi đè dịch vụ cấp phòng ──────────────────────────────────────────
        dto.setOverrideServices(room.getOverrideServices());
        dto.setOverrideGarbageFee(room.getOverrideGarbageFee());
        dto.setOverrideInternetFee(room.getOverrideInternetFee());
        dto.setOverrideParkingFee(room.getOverrideParkingFee());

        // ── Full 5-step room configuration ────────────────────────────────────
        // Cột jsonb `detailed_info` chứa toàn bộ dữ liệu chủ trọ nhập ở wizard
        // (nội thất, chỉ số đồng hồ, ảnh đặc trưng, số người tối đa, hướng...).
        // Trước đây bị bỏ quên → trang chi tiết phòng đã đăng trống trơn so với
        // lúc xem trước. Nay trả nguyên vẹn để preview == published.
        dto.setDetailedInfo(room.getDetailedInfo());

        // ── Branch (toà nhà) info ─────────────────────────────────────────────
        // Nguồn giá dịch vụ (điện/nước/mạng/gửi xe/rác) + tiện ích chung.
        // Frontend đọc các field này để dựng khối "Chi phí" và "Tiện ích toà nhà".
        // Dùng branchMap đã batch-load (tránh N+1).
        if (room.getBranchId() != null) {
            Branch branch = branchMap.get(room.getBranchId());
            if (branch != null) {
                dto.setBranchName(branch.getBranchName());
                dto.setBranchAddress(branch.getAddress());
                // BUGFIX: toạ độ toà nhà — dùng cho "Tiện ích xung quanh" (POI) khi
                // phòng chưa gắn lat/lng. Trước đây bị bỏ qua → POI trang đã đăng
                // trống/lệch so với preview.
                dto.setBranchLatitude(branch.getLatitude());
                dto.setBranchLongitude(branch.getLongitude());
                dto.setInternetPrice(branch.getInternetFee());
                dto.setParkingPrice(branch.getParkingFee());
                dto.setTrashPrice(branch.getGarbageFee());
                dto.setWaterPricingType(
                        branch.getWaterPricingType() != null ? branch.getWaterPricingType().name() : null);
                dto.setBranchAmenities(parseBranchAmenities(branch.getAmenities()));
            }
        }

        // ── Ghi đè dịch vụ cấp PHÒNG (override_services = true) ────────────────
        // Phòng có thể ghi đè giá mạng/gửi xe/rác của chi nhánh. Trước đây bị bỏ
        // qua hoàn toàn → hiển thị sai giá so với lúc chủ trọ cấu hình.
        if (Boolean.TRUE.equals(room.getOverrideServices())) {
            if (room.getOverrideInternetFee() != null) dto.setInternetPrice(room.getOverrideInternetFee());
            if (room.getOverrideParkingFee() != null) dto.setParkingPrice(room.getOverrideParkingFee());
            if (room.getOverrideGarbageFee() != null) dto.setTrashPrice(room.getOverrideGarbageFee());
        }

        // Owner — dùng ownerMap đã batch-load (tránh N+1).
        User owner = room.getOwnerId() != null ? ownerMap.get(room.getOwnerId()) : null;
        if (owner != null) {
            dto.setOwnerName(owner.getName());
            dto.setOwnerPhone(owner.getPhoneNumber());
            dto.setOwnerAvatar(owner.getAvatarUrl());
            dto.setIsSuperLandlord("VERIFIED".equals(owner.getAccountStatus()));
        }

        // Post
        dto.setPostId(post.getId());
        dto.setPostTitle(post.getPostTitle());
        // BUGFIX: frontend đọc `title` để hiển thị tiêu đề tin đăng (feed card +
        // detail sheet). Trước đây DTO thiếu field này → luôn rơi về roomName.
        dto.setTitle(post.getPostTitle());
        
        dto.setCoverImageUrl(post.getCoverImageUrl());
        dto.setPostImages(post.getPostImages());
        dto.setPostStatus(post.getStatus());
        dto.setPostCreatedAt(post.getCreatedAt());

        // Promotion
        if (promo != null && Boolean.TRUE.equals(promo.getIsActive())) {
            dto.setHasPromotion(true);
            dto.setPromotionId(promo.getId());
            dto.setDiscountType(promo.getDiscountType());
            dto.setDiscountAmount(promo.getDiscountAmount());
            dto.setDiscountPercent(promo.getDiscountPercent());
            dto.setMaxDiscountAmount(promo.getMaxDiscountAmount());
            dto.setMonthsPerTenant(promo.getMonthsPerTenant());
            dto.setTotalMonths(0); // Vouchers typically don't have totalMonths natively in this model
            dto.setUsedMonths(0);
            dto.setRemainingMonths(promo.getRemainingUsages() == Integer.MAX_VALUE ? -1 : promo.getRemainingUsages());
            dto.setPromotionDescription(promo.getDescription());
            dto.setPromotionEndDate(promo.getEndDate());

            double orig = room.getPrice() != null ? room.getPrice() : 0;
            dto.setOriginalPrice(orig);
            dto.setPromotionPrice(promo.computeDiscountedPrice(orig));
            dto.setBadgeLabel(buildBadgeLabel(promo));
        } else {
            dto.setHasPromotion(false);
        }

        // Engagement
        dto.setWishlistCount(wishlistCount);

        return dto;
    }

    /**
     * Parse cột {@code amenities} của Branch (JSON array dạng
     * {@code [{"name":"Wifi","price":100000,"chargeType":"monthly"}]}) thành
     * List<Map> để serialize thẳng ra JSON cho frontend.
     *
     * <p>Trả về {@code null} nếu rỗng/không parse được — frontend đã có fallback.
     */
    @SuppressWarnings("unchecked")
    private java.util.List<java.util.Map<String, Object>> parseBranchAmenities(String raw) {
        if (raw == null || raw.trim().isEmpty()) return null;
        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            java.util.List<java.util.Map<String, Object>> list =
                    mapper.readValue(raw, java.util.List.class);
            return (list == null || list.isEmpty()) ? null : list;
        } catch (Exception e) {
            return null;
        }
    }

    private String buildBadgeLabel(com.stayhub.api.entity.Voucher p) {
        if (p.getDiscountType() == com.stayhub.api.entity.Voucher.DiscountType.PERCENTAGE && p.getDiscountPercent() != null) {
            return String.format("%.0f%% OFF", p.getDiscountPercent());
        } else if (p.getDiscountType() == com.stayhub.api.entity.Voucher.DiscountType.FIXED_AMOUNT && p.getDiscountAmount() != null) {
            java.text.NumberFormat fmt = java.text.NumberFormat.getNumberInstance(new java.util.Locale("vi", "VN"));
            return "-" + fmt.format(p.getDiscountAmount().longValue()) + "đ";
        }
        return "ƯU ĐÃI";
    }

    private RoomPostDTO mapToDTO(RoomPost post) {
        RoomPostDTO dto = new RoomPostDTO();
        dto.setId(post.getId());
        dto.setRoomId(post.getRoomId());
        dto.setOwnerId(post.getOwnerId());
        dto.setPostTitle(post.getPostTitle());
        
        // 1 phòng chỉ có 1 mô tả: luôn lấy từ Room entity
        roomRepository.findById(post.getRoomId()).ifPresent(room -> {
            dto.setPostDescription(room.getDescription());
        });
        
        dto.setCoverImageUrl(post.getCoverImageUrl());
        dto.setPostImages(post.getPostImages());
        dto.setRentingPrice(post.getRentingPrice());
        dto.setDeposit(post.getDeposit());
        dto.setHasPromotion(post.getHasPromotion());
        dto.setDiscountType(post.getDiscountType());
        dto.setDiscountAmount(post.getDiscountAmount());
        dto.setPromotionMonths(post.getPromotionMonths());
        dto.setPromotionDescription(post.getPromotionDescription());
        dto.setStatus(post.getStatus());
        dto.setCreatedAt(post.getCreatedAt());
        dto.setUpdatedAt(post.getUpdatedAt());
        return dto;
    }
}
