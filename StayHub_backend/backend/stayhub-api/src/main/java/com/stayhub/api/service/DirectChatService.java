package com.stayhub.api.service;

import com.stayhub.api.dto.request.DirectChatMessageRequest;
import com.stayhub.api.dto.response.DirectChatMessageDto;
import com.stayhub.api.entity.DirectChatMessage;
import com.stayhub.api.repository.DirectChatMessageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DirectChatService {
    
    private final DirectChatMessageRepository repository;

    @Transactional(readOnly = true)
    public List<DirectChatMessageDto> getHistory(Long user1Id, Long user2Id) {
        return repository.findChatHistory(user1Id, user2Id).stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public DirectChatMessageDto sendMessage(Long senderId, DirectChatMessageRequest request) {
        DirectChatMessage msg = DirectChatMessage.builder()
                .senderId(senderId)
                .receiverId(request.getReceiverId())
                .content(request.getContent())
                .messageType(request.getMessageType() != null ? request.getMessageType() : "TEXT")
                .isRead(false)
                .build();
        
        return mapToDto(repository.save(msg));
    }

    private DirectChatMessageDto mapToDto(DirectChatMessage entity) {
        return DirectChatMessageDto.builder()
                .id(entity.getId())
                .senderId(entity.getSenderId())
                .receiverId(entity.getReceiverId())
                .content(entity.getContent())
                .messageType(entity.getMessageType())
                .isRead(entity.isRead())
                .createdAt(entity.getCreatedAt())
                .build();
    }
}
