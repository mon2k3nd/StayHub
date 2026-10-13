package com.stayhub.api.service;

import org.springframework.http.codec.ServerSentEvent;
import reactor.core.publisher.Flux;

import java.util.UUID;

public interface ChatService {
    Flux<ServerSentEvent<String>> streamChat(UUID conversationId, String prompt, Long userId);
}
