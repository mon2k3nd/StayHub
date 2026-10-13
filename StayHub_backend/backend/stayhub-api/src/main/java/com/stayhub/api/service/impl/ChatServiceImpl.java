package com.stayhub.api.service.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.stayhub.api.entity.ChatMessage;
import com.stayhub.api.entity.Conversation;
import com.stayhub.api.repository.ChatMessageRepository;
import com.stayhub.api.repository.ConversationRepository;
import com.stayhub.api.service.ChatService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatServiceImpl implements ChatService {

    private final WebClient geminiWebClient;
    private final ChatMessageRepository chatMessageRepository;
    private final ConversationRepository conversationRepository;
    private final ObjectMapper objectMapper;

    @Override
    public Flux<ServerSentEvent<String>> streamChat(UUID conversationId, String prompt, Long userId) {
        AtomicReference<String> fullAiResponse = new AtomicReference<>("");

        // 1. Fetch history safely without blocking WebFlux threads
        Mono<List<ChatMessage>> historyMono = Mono.fromCallable(() -> {
            // Create conversation if it doesn't exist
            conversationRepository.findById(conversationId).orElseGet(() -> {
                Conversation conv = Conversation.builder()
                        .id(conversationId)
                        .userId(userId)
                        .title("Chat " + LocalDateTime.now().toLocalDate())
                        .build();
                return conversationRepository.save(conv);
            });

            // Save user prompt
            ChatMessage userMsg = ChatMessage.builder()
                    .conversationId(conversationId)
                    .senderType("USER")
                    .content(prompt)
                    .status("SENT")
                    .build();
            chatMessageRepository.save(userMsg);

            List<ChatMessage> history = chatMessageRepository.findTop10ByConversationIdOrderByCreatedAtDesc(conversationId);
            Collections.reverse(history); // Oldest first for context
            return history;
        }).subscribeOn(Schedulers.boundedElastic());

        // 2. Build WebClient Flux
        return historyMono.flatMapMany(history -> {
            ObjectNode requestBody = buildGeminiRequest(history, prompt);

            return geminiWebClient.post()
                    .uri("/v1beta/models/gemini-1.5-pro:streamGenerateContent?alt=sse")
                    .bodyValue(requestBody)
                    .accept(MediaType.TEXT_EVENT_STREAM)
                    .retrieve()
                    .bodyToFlux(String.class)
                    .map(this::extractTextFromGeminiChunk)
                    .filter(text -> text != null && !text.isEmpty())
                    .doOnNext(text -> {
                        // Aggregate the response text
                        fullAiResponse.set(fullAiResponse.get() + text);
                    })
                    .map(text -> ServerSentEvent.<String>builder().data(text).build())
                    .doOnComplete(() -> {
                        // 3. Save AI response asynchronously when stream finishes
                        Mono.fromRunnable(() -> {
                            ChatMessage aiMsg = ChatMessage.builder()
                                    .conversationId(conversationId)
                                    .senderType("AI")
                                    .content(fullAiResponse.get())
                                    .status("DELIVERED")
                                    .build();
                            chatMessageRepository.save(aiMsg);
                        }).subscribeOn(Schedulers.boundedElastic()).subscribe();
                    })
                    .doOnError(e -> log.error("Error streaming from Gemini: ", e));
        });
    }

    private ObjectNode buildGeminiRequest(List<ChatMessage> history, String prompt) {
        ObjectNode rootNode = objectMapper.createObjectNode();
        ArrayNode contentsArray = rootNode.putArray("contents");

        // Append history context
        for (ChatMessage msg : history) {
            // Exclude the current prompt as it's already in history (saved in callable)
            // Wait, we saved it, so it's in history. Let's just map the history directly.
            ObjectNode contentNode = contentsArray.addObject();
            contentNode.put("role", msg.getSenderType().equals("USER") ? "user" : "model");
            ArrayNode partsArray = contentNode.putArray("parts");
            partsArray.addObject().put("text", msg.getContent());
        }

        return rootNode;
    }

    private String extractTextFromGeminiChunk(String chunkJson) {
        try {
            JsonNode root = objectMapper.readTree(chunkJson);
            if (root.has("candidates") && root.get("candidates").isArray() && root.get("candidates").size() > 0) {
                JsonNode content = root.get("candidates").get(0).get("content");
                if (content.has("parts") && content.get("parts").isArray() && content.get("parts").size() > 0) {
                    return content.get("parts").get(0).get("text").asText();
                }
            }
        } catch (Exception e) {
            log.warn("Failed to parse Gemini chunk: {}", chunkJson);
        }
        return "";
    }
}
