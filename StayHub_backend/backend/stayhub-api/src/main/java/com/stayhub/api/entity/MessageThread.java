package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "message_threads")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MessageThread {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id_1", nullable = false)
    private Long userId1;

    @Column(name = "user_id_2", nullable = false)
    private Long userId2;

    @Column(name = "room_id")
    private Long roomId;

    @Column(name = "branch_id")
    private Long branchId;

    @Column(name = "thread_type", nullable = false)
    private String threadType; // "INQUIRY", "DIRECT", "NEIGHBOR", "BRANCH_GROUP"

    @CreationTimestamp
    @Column(name = "created_at", updatable = false, nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(name = "last_message_content", columnDefinition = "TEXT")
    private String lastMessageContent;

    @Column(name = "last_sender_id")
    private Long lastSenderId;

    @Column(name = "last_sender_name")
    private String lastSenderName;

    @Column(name = "user1_last_read")
    private LocalDateTime user1LastRead;

    @Column(name = "user2_last_read")
    private LocalDateTime user2LastRead;

    @Column(name = "user1_is_deleted")
    @Builder.Default
    private Boolean user1IsDeleted = false;

    @Column(name = "user2_is_deleted")
    @Builder.Default
    private Boolean user2IsDeleted = false;

    @Column(name = "user1_is_saved")
    @Builder.Default
    private Boolean user1IsSaved = false;

    @Column(name = "user2_is_saved")
    @Builder.Default
    private Boolean user2IsSaved = false;
}
