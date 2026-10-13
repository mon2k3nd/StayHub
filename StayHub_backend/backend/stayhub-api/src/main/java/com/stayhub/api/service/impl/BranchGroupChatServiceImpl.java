package com.stayhub.api.service.impl;

import com.stayhub.api.dto.request.BranchGroupMessageRequest;
import com.stayhub.api.dto.response.BranchGroupMessageDto;
import com.stayhub.api.entity.Branch;
import com.stayhub.api.entity.BranchGroupMessage;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.BranchGroupMessageRepository;
import com.stayhub.api.repository.BranchRepository;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.service.BranchGroupChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BranchGroupChatServiceImpl implements BranchGroupChatService {

    private final BranchGroupMessageRepository messageRepository;
    private final BranchRepository branchRepository;
    private final ContractRepository contractRepository;
    private final UserRepository userRepository;
    private final com.stayhub.api.service.PushNotificationService pushNotificationService;

    @Override
    public List<BranchGroupMessageDto> getHistory(Long branchId) {
        return messageRepository.findByBranchIdOrderByCreatedAtAsc(branchId)
                .stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Override
    public BranchGroupMessageDto sendMessage(Long branchId, Long senderId, BranchGroupMessageRequest request) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new RuntimeException("Branch not found"));
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        String role = "TENANT";
        String roomNumber = null;

        if (branch.getOwnerId().equals(senderId)) {
            role = "OWNER";
        } else {
            List<String> rooms = contractRepository.findActiveRoomNamesByTenantAndBranch(senderId, branchId);
            if (rooms.isEmpty()) {
                throw new RuntimeException("User is not a tenant of this branch");
            }
            roomNumber = rooms.get(0);
        }

        BranchGroupMessage message = BranchGroupMessage.builder()
                .branchId(branchId)
                .senderId(senderId)
                .senderName(sender.getName())
                .senderRole(role)
                .roomNumber(roomNumber)
                .messageType(request.getMessageType() != null ? request.getMessageType() : "TEXT")
                .content(request.getContent())
                .build();

        BranchGroupMessage saved = messageRepository.save(message);

        // Gửi Push Notification cho tất cả những người khác trong nhóm
        List<Long> receiverIds = new java.util.ArrayList<>();
        if (!branch.getOwnerId().equals(senderId)) {
            receiverIds.add(branch.getOwnerId());
        }
        List<Long> tenantIds = contractRepository.findActiveTenantIdsByBranch(branchId);
        for (Long tId : tenantIds) {
            if (!tId.equals(senderId) && !receiverIds.contains(tId)) {
                receiverIds.add(tId);
            }
        }

        String preview = request.getContent() != null && request.getContent().length() > 100 ? request.getContent().substring(0, 100) + "..." : request.getContent();
        for (Long rId : receiverIds) {
            User r = userRepository.findById(rId).orElse(null);
            if (r != null && r.getFcmToken() != null && !r.getFcmToken().isBlank()) {
                pushNotificationService.sendToDevice(
                        r.getFcmToken(),
                        "Nhóm dãy " + branch.getBranchName() + " (Tin nhắn mới)",
                        sender.getName() + ": " + preview,
                        java.util.Map.of("type", "branch_chat", "branchId", String.valueOf(branchId))
                );
            }
        }

        return mapToDto(saved);
    }

    @Override
    public void sendSystemMessage(Long branchId, String content) {
        BranchGroupMessage message = BranchGroupMessage.builder()
                .branchId(branchId)
                .senderId(null)
                .senderName("Hệ thống")
                .senderRole("SYSTEM")
                .messageType("TEXT")
                .content(content)
                .build();
        messageRepository.save(message);
    }

    private BranchGroupMessageDto mapToDto(BranchGroupMessage msg) {
        return BranchGroupMessageDto.builder()
                .id(msg.getId())
                .branchId(msg.getBranchId())
                .senderId(msg.getSenderId())
                .senderName(msg.getSenderName())
                .senderRole(msg.getSenderRole())
                .roomNumber(msg.getRoomNumber())
                .messageType(msg.getMessageType())
                .content(msg.getContent())
                .createdAt(msg.getCreatedAt())
                .build();
    }
}
