package com.stayhub.api.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.File;

@Configuration
@Slf4j
public class FirebaseConfig {

    @PostConstruct
    public void init() {
        try {
            // Check if Firebase is already initialized
            if (!FirebaseApp.getApps().isEmpty()) {
                return;
            }

            // Path to your service account key file
            // Note: For a real production app, this should be provided via env var or secret manager
            String serviceAccountPath = "stayhub-firebase-adminsdk.json";
            File file = new File(serviceAccountPath);

            if (!file.exists()) {
                log.warn("Firebase service account file not found at {}. Firebase Admin SDK will not be initialized. Push notifications will be mocked.", serviceAccountPath);
                return;
            }

            InputStream serviceAccount = new FileInputStream(file);

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            FirebaseApp.initializeApp(options);
            log.info("Firebase Admin SDK initialized successfully.");

        } catch (Exception e) {
            log.error("Failed to initialize Firebase Admin SDK: {}", e.getMessage());
        }
    }
}
