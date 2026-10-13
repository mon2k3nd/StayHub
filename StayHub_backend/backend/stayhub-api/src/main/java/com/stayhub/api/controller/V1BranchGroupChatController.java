package com.stayhub.api.controller;

import com.stayhub.api.dto.request.BranchGroupMessageRequest;
import com.stayhub.api.dto.response.BranchGroupMessageDto;
import com.stayhub.api.service.BranchGroupChatService;
import com.stayhub.api.service.CloudStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@RestController
@RequestMapping("/v1/branches/{branchId}/chat")
@RequiredArgsConstructor
public class V1BranchGroupChatController {

    private final BranchGroupChatService chatService;
    private final CloudStorageService cloudStorageService;
    private final Map<Long, List<SseEmitter>> emitters = new ConcurrentHashMap<>();

    @GetMapping
    public ResponseEntity<List<BranchGroupMessageDto>> getHistory(@PathVariable Long branchId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        verifyBranchAccess(branchId, auth);
        return ResponseEntity.ok(chatService.getHistory(branchId));
    }

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter subscribe(@PathVariable Long branchId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        verifyBranchAccess(branchId, auth);
        SseEmitter emitter = new SseEmitter(Long.MAX_VALUE); com.stayhub.api.service.SseHeartbeatService.register(emitter);
        emitters.computeIfAbsent(branchId, k -> new CopyOnWriteArrayList<>()).add(emitter);

        emitter.onCompletion(() -> removeEmitter(branchId, emitter));
        emitter.onTimeout(() -> removeEmitter(branchId, emitter));
        emitter.onError((e) -> removeEmitter(branchId, emitter));

        try {
            emitter.send(SseEmitter.event().name("CONNECT").data("Connected to branch chat " + branchId));
        } catch (IOException e) {
            removeEmitter(branchId, emitter);
        }

        return emitter;
    }

    private void removeEmitter(Long branchId, SseEmitter emitter) {
        List<SseEmitter> list = emitters.get(branchId);
        if (list != null) {
            list.remove(emitter);
        }
    }

    @PostMapping(consumes = { MediaType.MULTIPART_FORM_DATA_VALUE, MediaType.APPLICATION_JSON_VALUE })
    public ResponseEntity<BranchGroupMessageDto> sendMessage(
            @PathVariable Long branchId,
            org.springframework.security.core.Authentication auth,
            @RequestParam(value = "messageType", defaultValue = "TEXT") String messageType,
            @RequestParam(value = "content", required = false) String content,
            @RequestPart(value = "file", required = false) MultipartFile file) {
        
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        verifyBranchAccess(branchId, auth);
        Long senderId = (Long) auth.getPrincipal();
        String finalContent = content;
        if (file != null && !file.isEmpty()) {
            try {
                finalContent = cloudStorageService.uploadFile(file);
            } catch (Exception e) {
                throw new RuntimeException("Failed to upload file");
            }
        }

        BranchGroupMessageRequest request = BranchGroupMessageRequest.builder()
                .messageType(messageType)
                .content(finalContent)
                .build();
        
        BranchGroupMessageDto msg = chatService.sendMessage(branchId, senderId, request);
        
        // Broadcast
        List<SseEmitter> list = emitters.get(branchId);
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name("MESSAGE").data(msg));
                } catch (IOException e) {
                    emitter.complete();
                    removeEmitter(branchId, emitter);
                }
            }
        }
        
        return ResponseEntity.ok(msg);
    }
    
    private void verifyBranchAccess(Long branchId, org.springframework.security.core.Authentication auth) {
        Long userId = (Long) auth.getPrincipal();
        boolean isStaff = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_STAFF"));
        boolean isTenant = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ACTIVE_TENANT"));
        
        com.stayhub.api.entity.Branch branch = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.BranchRepository.class).findById(branchId).orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND));
        
        if (isTenant) {
            java.util.List<com.stayhub.api.entity.Contract> contracts = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.ContractRepository.class).findByTenantId(userId);
            for (com.stayhub.api.entity.Contract c : contracts) {
                if (c.getStatus() == com.stayhub.api.entity.ContractStatus.ACTIVE) {
                    com.stayhub.api.entity.Room r = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.repository.RoomRepository.class).findById(c.getRoomId()).orElse(null);
                    if (r != null && r.getBranchId().equals(branchId)) return;
                }
            }
        }
        
        if (isStaff) {
            java.util.List<com.stayhub.api.entity.StaffAssignment> assignments = com.stayhub.api.config.ApplicationContextProvider.getApplicationContext().getBean(com.stayhub.api.service.StaffService.class).getAssignments(userId);
            if (assignments.stream().anyMatch(a -> a.getBranchId().equals(branchId))) return;
        } else if (branch.getOwnerId().equals(userId)) {
            return;
        }
        
        throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền chat trong nhóm này");
    }
}
