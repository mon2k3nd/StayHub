package com.stayhub.api.service;

import com.stayhub.api.dto.request.MarketplacePostRequestDto;
import com.stayhub.api.dto.response.MarketplacePostDto;

import java.util.List;

public interface MarketplaceService {
    List<MarketplacePostDto> getActivePosts();
    MarketplacePostDto createPost(String email, MarketplacePostRequestDto request);
    void deletePost(String email, Long postId);
}
