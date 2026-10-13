package com.stayhub.api;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import java.util.List;
import java.util.Map;

@SpringBootTest
public class FixBranchBugTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    public void investigateAndFix() {
        System.out.println("=== BRANCH INVESTIGATION ===");
        List<Map<String, Object>> branches = jdbcTemplate.queryForList(
            "SELECT id, branch_name, address, is_active, creation_status FROM branches WHERE address LIKE '%351%'"
        );
        for (Map<String, Object> b : branches) {
            System.out.println("Branch: " + b);
        }
        
        // Force delete the empty one
        int deleted = jdbcTemplate.update("DELETE FROM branches WHERE address LIKE '%351%' AND is_active = true AND id IN (SELECT branch_id FROM (SELECT b.id as branch_id, COUNT(r.id) as rc FROM branches b LEFT JOIN rooms r ON b.id = r.branch_id GROUP BY b.id HAVING COUNT(r.id) = 0) as empty_branches)");
        System.out.println("Deleted empty branches: " + deleted);
    }
}
