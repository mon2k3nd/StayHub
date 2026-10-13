package com.stayhub.api;

import com.stayhub.api.service.AdminService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
public class AdminServiceCrashTest {

    @Autowired
    private AdminService adminService;

    @Test
    public void testGetDashboardStats() {
        try {
            System.out.println("TEST_START: Fetching stats...");
            var stats = adminService.getDashboardStats();
            System.out.println("TEST_SUCCESS: " + stats);
        } catch (Exception e) {
            e.printStackTrace();
            throw e;
        }
    }
}
