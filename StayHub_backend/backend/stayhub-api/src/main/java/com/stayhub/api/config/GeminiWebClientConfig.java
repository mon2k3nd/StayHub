package com.stayhub.api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class GeminiWebClientConfig {

    @Value("${GEMINI_API_KEY:}")
    private String geminiApiKey;

    @Bean
    public WebClient geminiWebClient(WebClient.Builder webClientBuilder) {
        return webClientBuilder
                .baseUrl("https://generativelanguage.googleapis.com")
                .defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                .defaultHeader("x-goog-api-key", geminiApiKey)
                .build();
    }
}
