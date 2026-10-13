package com.stayhub.api.controller;

import com.stayhub.api.config.CheckRole;
import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.User;
import com.stayhub.api.entity.TenantProfile;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.service.TenantProfileService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

@RestController
@RequestMapping("/v1/tenant")
@RequiredArgsConstructor
@Slf4j
@CheckRole({"USER", "TENANT", "ACTIVE_TENANT"})
public class V1TenantController {

    private final UserRepository userRepository;
    private final TenantProfileService tenantProfileService;

    @PutMapping("/request-owner")
    public ResponseEntity<ApiResponse<User>> requestOwner(
            Authentication auth,
            @RequestBody Map<String, Object> surveyData) {

        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }

        Long tenantId = (Long) auth.getPrincipal();
        User user = userRepository.findById(tenantId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy tài khoản người dùng"));

        log.info("Tenant ID {} submitted owner upgrade request. Survey data: {}", tenantId, surveyData);

        var op = user.getOwnerProfile();
        if (op == null) {
            op = new com.stayhub.api.entity.OwnerProfile();
            op.setUser(user);
            user.setOwnerProfile(op);
        }
        op.setRequestingOwner(true);
        User updatedUser = userRepository.save(user);

        return ResponseEntity.ok(ApiResponse.<User>builder()
                .success(true)
                .message("Đã gửi yêu cầu làm chủ nhà thành công!")
                .data(updatedUser)
                .build());
    }

    @PostMapping("/ekyc")
    @CheckRole({"USER", "TENANT", "ACTIVE_TENANT", "OWNER", "GUEST"})
    public ResponseEntity<ApiResponse<TenantProfile>> verifyEkyc(
            Authentication auth,
            @RequestBody Map<String, String> request) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long tenantId = (Long) auth.getPrincipal();
        String cccdNumber = request.get("cccdNumber");
        if (cccdNumber == null || cccdNumber.trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu số CCCD");
        }

        try {
            TenantProfile profile = tenantProfileService.verifyEkyc(tenantId, cccdNumber);
            return ResponseEntity.ok(ApiResponse.<TenantProfile>builder()
                    .success(true)
                    .message("Xác thực eKYC thành công!")
                    .data(profile)
                    .build());
        } catch (IllegalArgumentException e) {
            if ("CCCD_ALREADY_EXISTS".equals(e.getMessage())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "CCCD này đã được sử dụng bởi một tài khoản khác.");
            }
            throw e;
        }
    }

    @PostMapping(value = "/ekyc/upload", consumes = org.springframework.http.MediaType.MULTIPART_FORM_DATA_VALUE)
    @CheckRole({"USER", "TENANT", "ACTIVE_TENANT", "OWNER", "GUEST"})
    public ResponseEntity<ApiResponse<TenantProfile>> submitEkyc(
            Authentication auth,
            @RequestParam("cccdNumber") String cccdNumber,
            @RequestParam(value = "fullName", required = false) String fullName,
            @RequestParam(value = "dateOfBirth", required = false) String dateOfBirth,
            @RequestParam(value = "gender", required = false) String gender,
            @RequestParam(value = "hometown", required = false) String hometown,
            @RequestParam(value = "issuePlace", required = false) String issuePlace,
            @RequestParam(value = "issueDate", required = false) String issueDate,
            @RequestParam(value = "features", required = false) String features,
            @RequestParam(value = "cccdFront", required = false) org.springframework.web.multipart.MultipartFile cccdFront,
            @RequestParam(value = "cccdBack", required = false) org.springframework.web.multipart.MultipartFile cccdBack,
            @RequestParam(value = "selfie", required = false) org.springframework.web.multipart.MultipartFile selfie) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long tenantId = (Long) auth.getPrincipal();
        if (cccdNumber == null || cccdNumber.trim().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu số CCCD");
        }

        try {
            TenantProfile profile = tenantProfileService.submitEkyc(
                tenantId, cccdNumber, fullName, dateOfBirth, gender, hometown, issuePlace, issueDate, features, cccdFront, cccdBack, selfie
            );
            return ResponseEntity.ok(ApiResponse.<TenantProfile>builder()
                    .success(true)
                    .message("Hồ sơ eKYC đã được gửi để xét duyệt!")
                    .data(profile)
                    .build());
        } catch (IllegalArgumentException e) {
            if ("CCCD_ALREADY_EXISTS".equals(e.getMessage())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "CCCD này đã được sử dụng bởi một tài khoản khác.");
            }
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
    }

    @PostMapping("/ekyc/request-reverify")
    @CheckRole({"USER", "TENANT", "ACTIVE_TENANT", "OWNER", "GUEST"})
    public ResponseEntity<ApiResponse<Void>> requestReverify(Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Yêu cầu xác thực");
        }
        Long tenantId = (Long) auth.getPrincipal();

        try {
            tenantProfileService.requestReverify(tenantId);
            return ResponseEntity.ok(ApiResponse.<Void>builder()
                    .success(true)
                    .message("Yêu cầu xác thực lại đã được gửi đến Admin.")
                    .build());
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
    }
}
