package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.CommunityPost;
import com.stayhub.api.repository.CommunityPostRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.annotation.PostConstruct;

import java.util.List;

@RestController
@RequestMapping("/v1/community-board")
@RequiredArgsConstructor
public class V1CommunityBoardController {

    private final CommunityPostRepository repository;

    @PostConstruct
    public void seedData() {
        if (repository.count() == 0) {
            repository.save(CommunityPost.builder()
                    .authorName("Chủ Trọ (Admin)")
                    .authorRole("OWNER")
                    .content("Thông báo: Tối nay 20h sẽ có thợ đến bảo trì thang máy. Mong các bạn sắp xếp thời gian đi lại.")
                    .likes(12)
                    .comments(0)
                    .build());
                    
            repository.save(CommunityPost.builder()
                    .authorName("Nguyễn Văn A")
                    .authorRole("TENANT")
                    .content("Mọi người ơi, mình vừa chuyển đi nên pass lại cái tủ lạnh mini 90L giá 500k. Ai cần inb nhé! (Phòng 301)")
                    .likes(5)
                    .comments(2)
                    .build());
                    
            repository.save(CommunityPost.builder()
                    .authorName("Trần Thị B")
                    .authorRole("TENANT")
                    .content("Tối nay ai có đơn Shopee giao không ạ? Xuống lấy dùm mình với, mình đang đi làm chưa về kịp 😭")
                    .likes(2)
                    .comments(1)
                    .build());
        }
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<CommunityPost>>> getPosts() {
        return ResponseEntity.ok(ApiResponse.ok(repository.findAllByOrderByCreatedAtDesc()));
    }

    @PostMapping("/{id}/like")
    public ResponseEntity<ApiResponse<CommunityPost>> toggleLike(@PathVariable Long id) {
        CommunityPost post = repository.findById(id).orElseThrow();
        post.setLikes(post.getLikes() + 1);
        return ResponseEntity.ok(ApiResponse.ok(repository.save(post)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CommunityPost>> createPost(@RequestBody CommunityPost post, org.springframework.security.core.Authentication auth) {
        post.setAuthorName("Người Dùng StayHub");
        post.setAuthorRole("TENANT");
        if (auth != null && auth.getPrincipal() != null) {
            // Optional: get real name
        }
        return ResponseEntity.ok(ApiResponse.ok(repository.save(post)));
    }
}
