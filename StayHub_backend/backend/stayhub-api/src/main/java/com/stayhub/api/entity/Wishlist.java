package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "wishlists", indexes = {
    @Index(name = "idx_wishlist_user", columnList = "user_id"),
    @Index(name = "idx_wishlist_room", columnList = "room_id"),
    @Index(name = "idx_wishlist_user_room", columnList = "user_id, room_id", unique = true)
})
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Wishlist {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    // Snapshot tên phòng lúc lưu, dùng để hiển thị ngay cả khi phòng bị xoá
    @Column(name = "room_name_snapshot")
    private String roomNameSnapshot;

    @Column(name = "private_note", columnDefinition = "TEXT")
    private String privateNote;

    @Column(name = "is_visited")
    @Builder.Default
    private Boolean isVisited = false;
}
