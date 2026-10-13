package com.stayhub.api.controller;

import com.stayhub.api.dto.request.MarketplacePostRequestDto;
import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.service.MarketplaceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/v1/marketplace")
@RequiredArgsConstructor
public class V1MarketplaceController {

    private final MarketplaceService marketplaceService;

    @org.springframework.cache.annotation.Cacheable("marketplacePosts")
    @GetMapping("/posts")
    public ResponseEntity<?> getActivePosts() {
        return ResponseEntity.ok(ApiResponse.ok(marketplaceService.getActivePosts()));
    }

    @org.springframework.cache.annotation.CacheEvict(value = "marketplacePosts", allEntries = true)
    @PostMapping("/posts")
    public ResponseEntity<?> createPost(Authentication authentication, @RequestBody MarketplacePostRequestDto request) {
        return ResponseEntity.ok(ApiResponse.ok(marketplaceService.createPost(authentication.getName(), request)));
    }

    @org.springframework.cache.annotation.CacheEvict(value = "marketplacePosts", allEntries = true)
    @DeleteMapping("/posts/{id}")
    public ResponseEntity<?> deletePost(Authentication authentication, @PathVariable Long id) {
        marketplaceService.deletePost(authentication.getName(), id);
        return ResponseEntity.ok(ApiResponse.ok("Deleted"));
    }
}
