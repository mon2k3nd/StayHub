package com.stayhub.api;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.junit.jupiter.api.Test;
import java.util.Map;

public class CloudinaryBruteForceTest {

    @Test
    public void testCombinations() {
        String base64Image = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";
        
        char[] char2 = {'O', '0'};
        char[] char6 = {'I', 'l'};
        char[] char20 = {'O', '0'};
        
        boolean found = false;

        for (char c2 : char2) {
            for (char c6 : char6) {
                for (char c20 : char20) {
                    String secret = "Pf" + c2 + "gny" + c6 + "ihuYS8FtsM7s" + c20 + "yV3WyZU";
                    String url = "cloudinary://294849442516345:" + secret + "@iwhmbc7t";
                    System.out.println("Testing secret: " + secret);
                    
                    try {
                        Cloudinary cloudinary = new Cloudinary(url);
                        Map result = cloudinary.uploader().upload(base64Image, ObjectUtils.emptyMap());
                        System.out.println("============== SUCCESS ==============");
                        System.out.println("THE CORRECT SECRET IS: " + secret);
                        System.out.println("URL: " + result.get("secure_url"));
                        found = true;
                        break;
                    } catch (Exception e) {
                        // System.out.println("Failed: " + e.getMessage());
                    }
                }
                if (found) break;
            }
            if (found) break;
        }
        
        if (!found) {
            System.err.println("Could not find correct combination!");
            throw new RuntimeException("Brute force failed");
        }
    }
}
