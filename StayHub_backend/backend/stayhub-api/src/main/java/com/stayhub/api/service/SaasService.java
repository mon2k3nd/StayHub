package com.stayhub.api.service;

import com.stayhub.api.entity.SaasPlan;
import com.stayhub.api.entity.SaasSubscription;
import com.stayhub.api.repository.SaasPlanRepository;
import com.stayhub.api.repository.SaasSubscriptionRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class SaasService {

    private final SaasPlanRepository planRepository;
    private final SaasSubscriptionRepository subscriptionRepository;
    private final UserRepository userRepository;

    public void initPlansIfEmpty() {
        if (planRepository.count() == 0) {
            planRepository.save(SaasPlan.builder()
                .planType("FREE").name("Gói Cơ Bản").price(0.0).maxRooms(5).maxBranches(1).maxStaffs(1)
                .description("Phù hợp cho người mới bắt đầu").build());
                
            planRepository.save(SaasPlan.builder()
                .planType("PRO").name("Gói Nâng Cao").price(299000.0).maxRooms(50).maxBranches(3).maxStaffs(5)
                .description("Phù hợp cho chủ nhà chuyên nghiệp").build());
                
            planRepository.save(SaasPlan.builder()
                .planType("ENTERPRISE").name("Gói Toàn Diện").price(999000.0).maxRooms(1000).maxBranches(10).maxStaffs(50)
                .description("Không giới hạn tính năng").build());
        }
    }

    @Transactional
    public void buyPlan(Long ownerId, String planType) {
        SaasPlan plan = planRepository.findByPlanType(planType)
            .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy gói cước " + planType));
            
        // Expire current active plan if any
        subscriptionRepository.findTopByOwnerIdAndStatusOrderByEndDateDesc(ownerId, "ACTIVE")
            .ifPresent(sub -> {
                sub.setStatus("EXPIRED");
                sub.setEndDate(LocalDateTime.now());
                subscriptionRepository.save(sub);
            });
            
        // Create new active plan
        SaasSubscription newSub = SaasSubscription.builder()
            .ownerId(ownerId)
            .plan(plan)
            .startDate(LocalDateTime.now())
            .endDate(LocalDateTime.now().plusMonths(1))
            .status("ACTIVE")
            .amountPaid(plan.getPrice())
            .build();
            
        subscriptionRepository.save(newSub);
        
        // Sync to OwnerProfile for global checks
        User user = userRepository.findById(ownerId).orElse(null);
        if (user != null && user.getOwnerProfile() != null) {
            user.getOwnerProfile().setPackageId(plan.getPlanType());
            user.getOwnerProfile().setExpiredAt(newSub.getEndDate());
            userRepository.save(user);
        }
    }
    
    public SaasPlan getCurrentPlan(Long ownerId) {
        return subscriptionRepository.findTopByOwnerIdAndStatusOrderByEndDateDesc(ownerId, "ACTIVE")
            .map(SaasSubscription::getPlan)
            .orElseGet(() -> planRepository.findByPlanType("FREE").orElse(null));
    }

    public Map<String, Object> getAdminSaasStats() {
        Map<String, Object> response = new HashMap<>();
        
        List<SaasPlan> allPlans = planRepository.findAll();
        List<Map<String, Object>> plans = new ArrayList<>();
        
        double totalRevenue = 0;
        int totalActive = 0;
        int totalFreeActive = 0;
        
        for (SaasPlan plan : allPlans) {
            int activeUsers = subscriptionRepository.countActiveByPlanId(plan.getId());
            double revenue = subscriptionRepository.sumRevenueByPlanId(plan.getId());
            
            plans.add(createPlanStat(plan.getName(), activeUsers, revenue));
            
            totalRevenue += revenue;
            totalActive += activeUsers;
            if (plan.getPlanType().equals("FREE")) {
                totalFreeActive += activeUsers;
            }
        }
        
        response.put("plans", plans);
        
        Map<String, Object> summary = new HashMap<>();
        summary.put("totalRevenue", totalRevenue);
        
        double conversionRate = 0.0;
        if (totalActive > 0) {
            conversionRate = (double)(totalActive - totalFreeActive) / totalActive * 100.0;
        }
        summary.put("conversionRate", Math.round(conversionRate * 10.0) / 10.0);
        
        response.put("summary", summary);
        return response;
    }

    private Map<String, Object> createPlanStat(String name, int activeUsers, double revenue) {
        Map<String, Object> map = new HashMap<>();
        map.put("name", name);
        map.put("activeUsers", activeUsers);
        map.put("revenue", revenue);
        return map;
    }
    
    @Transactional
    public void updatePlan(String planType, Map<String, Object> payload) {
        SaasPlan plan = planRepository.findByPlanType(planType)
            .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy gói cước " + planType));
            
        if (payload.containsKey("price")) {
            plan.setPrice(Double.parseDouble(payload.get("price").toString()));
        }
        if (payload.containsKey("maxRooms")) {
            plan.setMaxRooms(Integer.parseInt(payload.get("maxRooms").toString()));
        }
        if (payload.containsKey("maxBranches")) {
            plan.setMaxBranches(Integer.parseInt(payload.get("maxBranches").toString()));
        }
        if (payload.containsKey("maxStaffs")) {
            plan.setMaxStaffs(Integer.parseInt(payload.get("maxStaffs").toString()));
        }
        planRepository.save(plan);
    }
}
