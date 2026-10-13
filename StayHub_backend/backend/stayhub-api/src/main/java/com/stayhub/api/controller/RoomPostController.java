package com.stayhub.api.controller;

import com.stayhub.api.dto.RoomPostDTO;
import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.service.RoomPostService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/v1/room-posts")
@RequiredArgsConstructor
public class RoomPostController {

    private final RoomPostService roomPostService;

    @PostMapping("/room/{roomId}")
    public ResponseEntity<ApiResponse<RoomPostDTO>> savePost(
            @PathVariable Long roomId,
            @RequestBody RoomPostDTO request,
            Authentication auth) {
        Long ownerId = (Long) auth.getPrincipal();
        RoomPostDTO saved = roomPostService.savePost(ownerId, roomId, request);
        return ResponseEntity.ok(ApiResponse.<RoomPostDTO>builder()
                .success(true)
                .message("Lưu tin đăng thành công")
                .data(saved)
                .build());
    }

    @GetMapping("/room/{roomId}")
    public ResponseEntity<ApiResponse<RoomPostDTO>> getPostByRoomId(@PathVariable Long roomId) {
        RoomPostDTO post = roomPostService.getPostByRoomId(roomId);
        if (post == null) {
            return ResponseEntity.ok(ApiResponse.<RoomPostDTO>builder()
                    .success(true)
                    .message("Phòng chưa có tin đăng")
                    .data(null)
                    .build());
        }
        return ResponseEntity.ok(ApiResponse.<RoomPostDTO>builder()
                .success(true)
                .message("Lấy thông tin tin đăng thành công")
                .data(post)
                .build());
    }

    @GetMapping("/owner")
    public ResponseEntity<ApiResponse<java.util.List<RoomPostDTO>>> getPostsByOwner(Authentication auth) {
        Long ownerId = (Long) auth.getPrincipal();
        java.util.List<RoomPostDTO> posts = roomPostService.getPostsByOwner(ownerId);
        return ResponseEntity.ok(ApiResponse.<java.util.List<RoomPostDTO>>builder()
                .success(true)
                .message("Lấy danh sách tin đăng của chủ nhà thành công")
                .data(posts)
                .build());
    }
}
