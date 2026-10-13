package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "branch_group_messages", indexes = {
        @Index(name = "idx_branch_id", columnList = "branch_id")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BranchGroupMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "branch_id", nullable = false)
    private Long branchId;

    @Column(name = "sender_id")
    private Long senderId; // Null for SYSTEM messages

    @Column(name = "sender_name")
    private String senderName;

    @Column(name = "sender_role")
    private String senderRole; // "OWNER", "TENANT", "SYSTEM"

    @Column(name = "room_number")
    private String roomNumber; // e.g. "101". Only applicable if role is TENANT

    @Column(name = "message_type")
    private String messageType; // "TEXT", "IMAGE", "VOICE"

    @Column(name = "content", columnDefinition = "TEXT", nullable = false)
    private String content;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false, nullable = false)
    private LocalDateTime createdAt;
}
