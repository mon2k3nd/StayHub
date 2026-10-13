package com.stayhub.api.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import java.util.Map;

@Service
@Slf4j
public class CloudStorageService {

    private final Cloudinary cloudinary;

    public CloudStorageService() {
        // Initialize Cloudinary with the provided URL
        this.cloudinary = new Cloudinary("cloudinary://294849442516345:Pf0gnyIihuYS8FtsM7sOyV3WyZU@iwhmbc7t");
    }

    public String uploadFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            return null;
        }
        try {
            Map uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap("resource_type", "auto"));
            String secureUrl = uploadResult.get("secure_url").toString();
            log.info("[CloudStorage] Uploaded file to Cloudinary: {}", secureUrl);
            return secureUrl;
        } catch (IOException e) {
            log.error("Failed to upload file to Cloudinary: {}", e.getMessage(), e);
            throw new RuntimeException("Lỗi tải tệp lên Cloudinary: " + e.getMessage());
        }
    }

    public String uploadBase64(String base64String) {
        if (base64String == null || base64String.isEmpty()) return null;
        // Ảnh đã là URL (Cloudinary) → giữ nguyên, không upload lại.
        if (base64String.startsWith("http")) return base64String;
        try {
            // Extract the raw base64 data by removing the data URI prefix if present
            String rawBase64 = base64String;
            if (base64String.contains(",")) {
                rawBase64 = base64String.substring(base64String.indexOf(",") + 1);
            }
            byte[] decodedBytes = java.util.Base64.getDecoder().decode(rawBase64);

            Map uploadResult = cloudinary.uploader().upload(decodedBytes, ObjectUtils.emptyMap());
            String secureUrl = uploadResult.get("secure_url").toString();
            log.info("[CloudStorage] Uploaded base64 image to Cloudinary: {}", secureUrl);
            return secureUrl;
        } catch (IOException | IllegalArgumentException e) {
            // IllegalArgumentException = base64 hỏng. Trả null để ảnh lỗi bị bỏ qua
            // thay vì làm hỏng toàn bộ thao tác lưu chi nhánh.
            log.error("Failed to upload base64 file to Cloudinary: {}", e.getMessage(), e);
            return null;
        }
    }
}
