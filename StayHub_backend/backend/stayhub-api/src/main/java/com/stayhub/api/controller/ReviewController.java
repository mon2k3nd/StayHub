package com.stayhub.api.controller;

import com.stayhub.api.entity.Review;
import com.stayhub.api.repository.ReviewRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/reviews")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", maxAge = 3600)
public class ReviewController {

    private final ReviewRepository reviewRepository;

    @GetMapping("/room/{roomId}")
    public ResponseEntity<List<Review>> getRoomReviews(@PathVariable Long roomId) {
        return ResponseEntity.ok(reviewRepository.findByRoomIdOrderByCreatedAtDesc(roomId));
    }
}
