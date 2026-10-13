package com.stayhub.api;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.junit.jupiter.api.Test;
import java.util.Map;

public class CloudinaryTest {

    @Test
    public void testUpload() {
        try {
            System.out.println("Initializing Cloudinary...");
            Cloudinary cloudinary = new Cloudinary("cloudinary://294849442516345:Pf0gnylihuYS8FtsM7sOyV3WyZU@iwhmbc7t");
            
            System.out.println("Uploading test image...");
            String base64Image = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";
            
            Map result = cloudinary.uploader().upload(base64Image, ObjectUtils.emptyMap());
            System.out.println("Upload successful! URL: " + result.get("secure_url"));
        } catch (Exception e) {
            System.err.println("Upload failed!");
            e.printStackTrace();
            throw new RuntimeException(e);
        }
    }
}
