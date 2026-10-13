package com.stayhub.api.controller;

import com.stayhub.api.entity.Room;
import com.stayhub.api.repository.RoomRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/ai")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", maxAge = 3600)
public class AiAdvisorController {

    private final RoomRepository roomRepository;

    @GetMapping("/advisor")
    public ResponseEntity<List<Room>> askAiAdvisor(@RequestParam String prompt) {
        List<Room> allRooms = roomRepository.findAll();
        
        // Mocking AI Matching Logic
        // In reality, this would use a Vector Database or OpenAI Embeddings
        String lowerPrompt = prompt.toLowerCase();
        
        List<Room> matchedRooms = allRooms.stream()
                .filter(room -> {
                    boolean matches = false;
                    String addr = room.getAddress() != null ? room.getAddress().toLowerCase() : "";
                    String desc = room.getDescription() != null ? room.getDescription().toLowerCase() : "";
                    String name = room.getRoomName() != null ? room.getRoomName().toLowerCase() : "";
                    
                    // Simple keyword matching for demo
                    if (lowerPrompt.contains("cầu giấy") && addr.contains("cầu giấy")) matches = true;
                    if (lowerPrompt.contains("đống đa") && addr.contains("đống đa")) matches = true;
                    if (lowerPrompt.contains("máy lạnh") && desc.contains("máy lạnh")) matches = true;
                    if (lowerPrompt.contains("nuôi pet") && desc.contains("pet")) matches = true;
                    
                    // Fallback to true if prompt is very short or just random
                    if (lowerPrompt.length() < 10) matches = true;
                    
                    return matches || addr.contains(lowerPrompt) || name.contains(lowerPrompt);
                })
                .limit(5)
                .collect(Collectors.toList());

        // Fallback if no matches
        if (matchedRooms.isEmpty()) {
            matchedRooms = allRooms.stream().limit(3).collect(Collectors.toList());
        }

        return ResponseEntity.ok(matchedRooms);
    }
}
