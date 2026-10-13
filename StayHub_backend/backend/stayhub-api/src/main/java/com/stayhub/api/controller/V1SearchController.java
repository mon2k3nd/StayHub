package com.stayhub.api.controller;

import com.stayhub.api.dto.response.GlobalSearchResponse;
import com.stayhub.api.service.SearchService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/v1/search")
@RequiredArgsConstructor
public class V1SearchController {

    private final SearchService searchService;

    @GetMapping
    public ResponseEntity<GlobalSearchResponse> search(
            @RequestParam("q") String query,
            Authentication authentication) {
        // extract ownerId from authentication
        Long ownerId = Long.parseLong(authentication.getName());
        return ResponseEntity.ok(searchService.globalSearch(ownerId, query));
    }
}
