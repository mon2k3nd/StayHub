package com.stayhub.api.service.impl;

import com.stayhub.api.dto.request.MarketplacePostRequestDto;
import com.stayhub.api.dto.response.MarketplacePostDto;
import com.stayhub.api.entity.MarketplacePost;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.MarketplacePostRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.service.MarketplaceService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.text.DecimalFormat;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class MarketplaceServiceImpl implements MarketplaceService {

    private final MarketplacePostRepository postRepository;
    private final UserRepository userRepository;

    @Override
    public List<MarketplacePostDto> getActivePosts() {
        return postRepository.findAllByStatusOrderByCreatedAtDesc("ACTIVE").stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Override
    public MarketplacePostDto createPost(String email, MarketplacePostRequestDto request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        MarketplacePost post = MarketplacePost.builder()
                .title(request.getTitle())
                .content(request.getContent())
                .price(request.getPrice())
                .tag(request.getTag())
                .tagColor(request.getTagColor())
                .status("ACTIVE")
                .author(user)
                // if we have logic to find room, we can set it here
                .build();

        postRepository.save(post);
        return mapToDto(post);
    }

    @Override
    public void deletePost(String email, Long postId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "User not found"));

        MarketplacePost post = postRepository.findById(postId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Post not found"));

        if (!post.getAuthor().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not your post");
        }

        post.setStatus("HIDDEN");
        postRepository.save(post);
    }

    private MarketplacePostDto mapToDto(MarketplacePost post) {
        String formattedPrice = "Miễn phí";
        if (post.getPrice() != null && post.getPrice() > 0) {
            DecimalFormat df = new DecimalFormat("#,###");
            formattedPrice = df.format(post.getPrice()) + " đ";
        }

        return MarketplacePostDto.builder()
                .id(post.getId())
                .title(post.getTitle())
                .content(post.getContent())
                .price(formattedPrice)
                .tag(post.getTag())
                .tagColor(post.getTagColor() != null ? post.getTagColor() : "0xFF34C759") // default green
                .status(post.getStatus())
                .author(post.getAuthor() != null ? post.getAuthor().getName() : "Người dùng")
                .room("N/A") // default
                .time(getTimeAgo(post.getCreatedAt()))
                .build();
    }

    private String getTimeAgo(LocalDateTime dateTime) {
        if (dateTime == null) return "Vừa xong";
        Duration diff = Duration.between(dateTime, LocalDateTime.now());
        if (diff.toMinutes() < 60) return diff.toMinutes() + " phút trước";
        if (diff.toHours() < 24) return diff.toHours() + " giờ trước";
        return diff.toDays() + " ngày trước";
    }
}
