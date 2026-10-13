package com.stayhub.api.service.impl;

import com.stayhub.api.entity.*;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.PackageSubscriptionRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.service.NotificationService;
import com.stayhub.api.service.PackageService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PackageServiceImpl implements PackageService {

    private final PackageSubscriptionRepository packageSubscriptionRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    private static final double PRO_PRICE  = 299_000;
    private static final double VIP_PRICE  = 599_000;

    @Override
    @Transactional
    public PackageSubscription subscribe(Long ownerId, PlanType packageType) {
        if (packageSubscriptionRepository.existsByOwnerIdAndStatus(ownerId, SubscriptionStatus.PENDING)) {
            throw new IllegalStateException("Bạn đã có yêu cầu đang chờ xử lý!");
        }
        double amount = packageType == PlanType.VIP ? VIP_PRICE : PRO_PRICE;
        String code = "STAYHUB " + packageType.name() + " OWNER" + ownerId;

        PackageSubscription sub = PackageSubscription.builder()
                .ownerId(ownerId)
                .packageType(packageType)
                .amount(amount)
                .transferCode(code)
                .status(SubscriptionStatus.PENDING)
                .build();

        return packageSubscriptionRepository.save(sub);
    }

    @Override
    public List<PackageSubscription> getPending() {
        return packageSubscriptionRepository.findByStatus(SubscriptionStatus.PENDING);
    }

    @Override
    @Transactional
    public void activate(Long subscriptionId, Long adminId) {
        PackageSubscription sub = packageSubscriptionRepository.findById(subscriptionId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy yêu cầu ID: " + subscriptionId));
        sub.setStatus(SubscriptionStatus.ACTIVE);
        sub.setActivatedBy(adminId);
        sub.setActivatedAt(LocalDateTime.now());
        sub.setExpiresAt(LocalDateTime.now().plusMonths(1));
        packageSubscriptionRepository.save(sub);

        // Cập nhật package của owner
        userRepository.findById(sub.getOwnerId()).ifPresent(user -> {
            var op = user.getOwnerProfile();
            if (op == null) {
                op = new com.stayhub.api.entity.OwnerProfile();
                op.setUser(user);
                user.setOwnerProfile(op);
            }
            op.setPackageId(sub.getPackageType().name());
            userRepository.save(user);
        });

        notificationService.send(null, sub.getOwnerId(), NotificationScope.INDIVIDUAL,
                "Gói " + sub.getPackageType().name() + " đã được kích hoạt!",
                "Tài khoản của bạn đã được nâng cấp lên gói " + sub.getPackageType().name() + ". Trải nghiệm đầy đủ tính năng ngay!",
                NotificationType.PACKAGE_ACTIVATED, subscriptionId, false, null, null);
    }

    @Override
    public List<PackageSubscription> getByOwner(Long ownerId) {
        return packageSubscriptionRepository.findByOwnerId(ownerId);
    }
}
