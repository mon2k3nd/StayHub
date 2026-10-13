package com.stayhub.api.controller;

import com.stayhub.api.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.*;
import reactor.core.publisher.Flux;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<String>> streamChat(
            @RequestParam UUID conversationId,
            @RequestParam String prompt,
            // Assuming user ID is extracted from security context in a real app,
            // passing it as a parameter here for simplicity
            @RequestParam(defaultValue = "1") Long userId) {

        return chatService.streamChat(conversationId, prompt, userId);
    }
}
