package com.stayhub.api.controller;

import com.stayhub.api.entity.OwnerContractTemplate;
import com.stayhub.api.repository.OwnerContractTemplateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/v1/owner-contract-templates")
@RequiredArgsConstructor
public class OwnerContractTemplateController {

    private final OwnerContractTemplateRepository repository;

    @GetMapping("/{ownerId}")
    public ResponseEntity<?> getTemplate(@PathVariable Long ownerId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Yêu cầu xác thực"));
        }
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(ownerId)) {
            return ResponseEntity.status(403).body(Map.of("success", false, "message", "Bạn không có quyền truy cập hợp đồng mẫu này"));
        }
        Optional<OwnerContractTemplate> template = repository.findById(ownerId);
        if (template.isPresent()) {
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "templateText", template.get().getTemplateText(),
                    "updatedAt", template.get().getUpdatedAt()
            ));
        } else {
            return ResponseEntity.ok(Map.of("success", true, "templateText", ""));
        }
    }

    @PostMapping("/{ownerId}")
    public ResponseEntity<?> saveTemplate(@PathVariable Long ownerId, @RequestBody Map<String, String> payload, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            return ResponseEntity.status(401).body(Map.of("success", false, "message", "Yêu cầu xác thực"));
        }
        Long userId = (Long) auth.getPrincipal();
        if (!userId.equals(ownerId)) {
            return ResponseEntity.status(403).body(Map.of("success", false, "message", "Bạn không có quyền sửa hợp đồng mẫu này"));
        }
        String templateText = payload.get("templateText");
        
        OwnerContractTemplate template = repository.findById(ownerId)
                .orElse(OwnerContractTemplate.builder().ownerId(ownerId).build());
                
        template.setTemplateText(templateText);
        template.setUpdatedAt(LocalDateTime.now());
        
        repository.save(template);
        
        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Đã lưu hợp đồng mẫu"
        ));
    }
}
