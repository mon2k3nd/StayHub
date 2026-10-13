package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.*;
import com.stayhub.api.repository.BranchRepository;
import com.stayhub.api.repository.RoomPostRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.repository.WishlistRepository;
import com.stayhub.api.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/v1/wishlist")
@RequiredArgsConstructor
@lombok.extern.slf4j.Slf4j
public class WishlistController {

    private final WishlistRepository wishlistRepository;
    private final RoomRepository roomRepository;
    private final BranchRepository branchRepository;
    private final RoomPostRepository roomPostRepository;
    private final NotificationService notificationService;
    private final com.stayhub.api.service.WebSocketSessionManager wsSessionManager;

    /**
     * GET /v1/wishlist/{userId}
     * Trả về danh sách phòng đã lưu, kèm trạng thái realtime (TRONG / DA_THUE).
     */
    @GetMapping("/{userId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> getWishlist(
            @PathVariable Long userId,
            org.springframework.security.core.Authentication auth) {
        // Validate: chỉ được xem wishlist của chính mình
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Yêu cầu xác thực").build());
        Long caller = (Long) auth.getPrincipal();
        if (!caller.equals(userId))
            return ResponseEntity.status(403).body(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Không có quyền xem wishlist của người khác").build());

        List<Wishlist> wishlist = wishlistRepository.findByUserIdOrderByCreatedAtDesc(userId);
        if (wishlist.isEmpty()) {
            Map<String, Object> result = new HashMap<>();
            result.put("available", Collections.emptyList());
            result.put("upcoming", Collections.emptyList());
            result.put("rented", Collections.emptyList());
            result.put("totalSaved", 0);
            return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                    .success(true)
                    .message("Lấy danh sách yêu thích thành công!")
                    .data(result)
                    .build());
        }

        // BATCH FETCHING để loại bỏ N+1 query: Lấy toàn bộ room 1 lần
        List<Long> roomIds = wishlist.stream().map(Wishlist::getRoomId).distinct().collect(Collectors.toList());
        Map<Long, Room> roomMap = roomRepository.findAllById(roomIds).stream()
                .collect(Collectors.toMap(Room::getId, r -> r));

        // Lấy toàn bộ branch liên quan 1 lần
        List<Long> branchIds = roomMap.values().stream()
                .map(Room::getBranchId)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, Branch> branchMap = branchIds.isEmpty() ? Collections.emptyMap() :
                branchRepository.findAllById(branchIds).stream()
                        .collect(Collectors.toMap(Branch::getId, b -> b));

        // Lấy toàn bộ room_post bài đăng cho thuê 1 lần
        Map<Long, RoomPost> postMap = roomIds.isEmpty() ? Collections.emptyMap() :
                roomPostRepository.findByRoomIdIn(roomIds).stream()
                        .collect(Collectors.toMap(RoomPost::getRoomId, p -> p, (p1, p2) -> p1));

        List<Map<String, Object>> available = new ArrayList<>();
        List<Map<String, Object>> upcoming = new ArrayList<>();
        List<Map<String, Object>> rented = new ArrayList<>();

        for (Wishlist w : wishlist) {
            Room room = roomMap.get(w.getRoomId());
            if (room == null) continue;

            Branch branch = room.getBranchId() != null ? branchMap.get(room.getBranchId()) : null;
            RoomPost post = postMap.get(room.getId());
            Map<String, Object> item = buildRoomItemOptimized(room, w, branch, post);

            if (room.getStatus() == RoomStatus.TRONG) {
                available.add(item);
            } else if (room.getStatus() == RoomStatus.SAP_TRONG) {
                upcoming.add(item);
            } else {
                rented.add(item);
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("available", available);
        result.put("upcoming", upcoming);
        result.put("rented", rented);
        result.put("totalSaved", wishlist.size());

        return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                .success(true)
                .message("Lấy danh sách yêu thích thành công!")
                .data(result)
                .build());
    }

    /**
     * PATCH /v1/wishlist/{userId}/note/{roomId}
     * Cập nhật ghi chú riêng tư hoặc trạng thái đã đi xem phòng thực tế.
     */
    @PatchMapping("/{userId}/note/{roomId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> updateWishlistNote(
            @PathVariable Long userId,
            @PathVariable Long roomId,
            @RequestBody Map<String, Object> body,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Yêu cầu xác thực").build());
        Long caller = (Long) auth.getPrincipal();
        if (!caller.equals(userId))
            return ResponseEntity.status(403).body(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Không có quyền").build());

        Optional<Wishlist> opt = wishlistRepository.findByUserIdAndRoomId(userId, roomId);
        if (opt.isEmpty()) {
            return ResponseEntity.status(404).body(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Phòng không nằm trong danh sách yêu thích").build());
        }

        Wishlist w = opt.get();
        if (body.containsKey("privateNote")) {
            w.setPrivateNote((String) body.get("privateNote"));
        }
        if (body.containsKey("isVisited")) {
            w.setIsVisited(Boolean.TRUE.equals(body.get("isVisited")));
        }
        wishlistRepository.save(w);

        return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                .success(true)
                .message("Cập nhật ghi chú thành công!")
                .data(Map.of("roomId", roomId, "privateNote", w.getPrivateNote() != null ? w.getPrivateNote() : "", "isVisited", Boolean.TRUE.equals(w.getIsVisited())))
                .build());
    }

    private Map<String, Object> buildRoomItemOptimized(Room room, Wishlist w, Branch branch, RoomPost post) {
        Map<String, Object> item = new HashMap<>();
        item.put("id", room.getId());
        item.put("roomId", room.getId());
        item.put("roomName", room.getRoomName());
        item.put("price", room.getPrice());
        item.put("address", room.getAddress());
        item.put("status", room.getStatus() != null ? room.getStatus().name() : "TRONG");
        item.put("roomImages", room.getRoomImages());
        item.put("description", room.getDescription());
        item.put("maxGuests", room.getMaxGuests());
        item.put("floorArea", room.getFloorArea());
        item.put("deposit", room.getDeposit());
        item.put("availableFrom", room.getAvailableFrom() != null ? room.getAvailableFrom().toString() : null);
        item.put("savedAt", w.getCreatedAt() != null ? w.getCreatedAt().toString() : null);
        item.put("privateNote", w.getPrivateNote());
        item.put("isVisited", Boolean.TRUE.equals(w.getIsVisited()));

        String coverImage = null;
        if (post != null) {
            item.put("postId", post.getId());
            item.put("postTitle", post.getPostTitle());
            item.put("coverImageUrl", post.getCoverImageUrl());
            item.put("postImages", post.getPostImages());
            coverImage = post.getCoverImageUrl();
            if (post.getRentingPrice() != null && post.getRentingPrice() > 0) {
                item.put("price", post.getRentingPrice());
            }
        }

        // Tạo tiêu đề (Title) chuẩn bài đăng hoặc toà nhà/chi nhánh + số phòng
        String displayTitle;
        if (post != null && post.getPostTitle() != null && !post.getPostTitle().isBlank()) {
            displayTitle = post.getPostTitle();
        } else if (branch != null && branch.getBranchName() != null && !branch.getBranchName().isBlank()) {
            displayTitle = branch.getBranchName() + " - " + (room.getRoomName().startsWith("Phòng") ? room.getRoomName() : "Phòng " + room.getRoomName());
        } else {
            displayTitle = room.getRoomName().startsWith("Phòng") ? room.getRoomName() : "Phòng " + room.getRoomName();
        }
        item.put("title", displayTitle);
        item.put("name", displayTitle);

        // Fallback ảnh bìa coverImageUrl nếu post chưa có
        if ((coverImage == null || coverImage.isBlank()) && room.getRoomImages() != null && !room.getRoomImages().isBlank()) {
            String rawImages = room.getRoomImages().trim();
            String firstImg = rawImages.replace("[", "").replace("]", "").replace("\"", "").replace("'", "").trim();
            if (firstImg.contains(",")) {
                firstImg = firstImg.split(",")[0].trim();
            }
            if (!firstImg.isBlank()) {
                item.put("coverImageUrl", firstImg);
            }
        }

        Double lat = room.getLatitude();
        Double lng = room.getLongitude();
        String branchAddress = null;
        if (branch != null) {
            item.put("branchId", branch.getId());
            if (lat == null) lat = branch.getLatitude();
            if (lng == null) lng = branch.getLongitude();
            branchAddress = branch.getAddress();
            item.put("branchName", branch.getBranchName());
            item.put("branchLatitude", branch.getLatitude());
            item.put("branchLongitude", branch.getLongitude());
        } else if (room.getBranchId() != null) {
            item.put("branchId", room.getBranchId());
        }

        item.put("latitude", lat);
        item.put("longitude", lng);
        if ((item.get("address") == null || item.get("address").toString().isBlank()) && branchAddress != null) {
            item.put("address", branchAddress);
        }

        return item;
    }

    /**
     * POST /v1/wishlist/{userId}/toggle/{roomId}
     * Thêm / Xóa phòng khỏi wishlist. Trả về { added: true/false }.
     */
    @PostMapping("/{userId}/toggle/{roomId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> toggle(
            @PathVariable Long userId,
            @PathVariable Long roomId,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Yêu cầu xác thực").build());
        Long caller = (Long) auth.getPrincipal();
        if (!caller.equals(userId))
            return ResponseEntity.status(403).body(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Không có quyền").build());

        Optional<Wishlist> existing = wishlistRepository.findByUserIdAndRoomId(userId, roomId);

        if (existing.isPresent()) {
            wishlistRepository.delete(existing.get());
            long newCount = wishlistRepository.countByRoomId(roomId);
            wsSessionManager.broadcastAll(
                "{\"type\":\"WISHLIST_COUNT_UPDATE\",\"roomId\":" + roomId + ",\"count\":" + newCount + "}");
            return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                    .success(true).message("Đã bỏ lưu phòng!")
                    .data(Map.of("added", false, "roomId", roomId, "wishlistCount", newCount))
                    .build());
        } else {
            String roomName = roomRepository.findById(roomId)
                    .map(Room::getRoomName).orElse("Phòng");
            Wishlist entry = Wishlist.builder()
                    .userId(userId)
                    .roomId(roomId)
                    .roomNameSnapshot(roomName)
                    .build();
            wishlistRepository.save(entry);
            long newCount = wishlistRepository.countByRoomId(roomId);
            wsSessionManager.broadcastAll(
                "{\"type\":\"WISHLIST_COUNT_UPDATE\",\"roomId\":" + roomId + ",\"count\":" + newCount + "}");
            return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                    .success(true).message("Đã lưu phòng!")
                    .data(Map.of("added", true, "roomId", roomId, "wishlistCount", newCount))
                    .build());
        }
    }
    /**
     * POST /v1/wishlist/{userId}/sync
     * Đồng bộ danh sách lưu từ Local Storage lên Server (sau khi login).
     * Body: { "roomIds": [1, 2, 3] }
     */
    @PostMapping("/{userId}/sync")
    public ResponseEntity<ApiResponse<Map<String, Object>>> sync(
            @PathVariable Long userId,
            @RequestBody Map<String, Object> body,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Yêu cầu xác thực").build());
        Long caller = (Long) auth.getPrincipal();
        if (!caller.equals(userId))
            return ResponseEntity.status(403).body(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Không có quyền").build());

        @SuppressWarnings("unchecked")
        List<Object> roomIdsRaw = (List<Object>) body.getOrDefault("roomIds", Collections.emptyList());

        int synced = 0;
        for (Object idObj : roomIdsRaw) {
            try {
                Long roomId = Long.valueOf(idObj.toString());
                if (!wishlistRepository.existsByUserIdAndRoomId(userId, roomId)) {
                    String roomName = roomRepository.findById(roomId)
                            .map(Room::getRoomName).orElse("Phòng");
                    Wishlist entry = Wishlist.builder()
                            .userId(userId)
                            .roomId(roomId)
                            .roomNameSnapshot(roomName)
                            .build();
                    wishlistRepository.save(entry);
                    synced++;
                }
            } catch (Exception ignored) { log.warn("Ignored exception in WishlistController: ", ignored); }
        }

        return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                .success(true)
                .message("Đã đồng bộ " + synced + " phòng mới lên server!")
                .data(Map.of("synced", synced, "total", roomIdsRaw.size()))
                .build());
    }

    /**
     * GET /v1/wishlist/{userId}/check/{roomId}
     * Kiểm tra 1 phòng có trong wishlist không (dùng khi mở trang chi tiết phòng).
     */
    @GetMapping("/{userId}/check/{roomId}")
    public ResponseEntity<ApiResponse<Boolean>> check(@PathVariable Long userId, @PathVariable Long roomId) {
        boolean exists = wishlistRepository.existsByUserIdAndRoomId(userId, roomId);
        return ResponseEntity.ok(ApiResponse.<Boolean>builder()
                .success(true).message("OK").data(exists).build());
    }

    /**
     * DELETE /v1/wishlist/{userId}
     * Xóa toàn bộ wishlist của user.
     */
    @DeleteMapping("/{userId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> clearAll(
            @PathVariable Long userId,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null)
            return ResponseEntity.status(401).body(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Yêu cầu xác thực").build());
        Long caller = (Long) auth.getPrincipal();
        if (!caller.equals(userId))
            return ResponseEntity.status(403).body(ApiResponse.<Map<String, Object>>builder()
                    .success(false).message("Không có quyền").build());
        List<Wishlist> all = wishlistRepository.findByUserIdOrderByCreatedAtDesc(userId);
        int count = all.size();
        wishlistRepository.deleteAll(all);
        return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                .success(true)
                .message("Đã xóa tất cả " + count + " phòng khỏi danh sách yêu thích!")
                .data(Map.of("deleted", count))
                .build());
    }



}
