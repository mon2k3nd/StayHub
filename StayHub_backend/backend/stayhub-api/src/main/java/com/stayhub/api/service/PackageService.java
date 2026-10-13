package com.stayhub.api.service;

import com.stayhub.api.entity.PackageSubscription;
import com.stayhub.api.entity.PlanType;
import java.util.List;

public interface PackageService {
    PackageSubscription subscribe(Long ownerId, PlanType packageType);
    List<PackageSubscription> getPending();
    void activate(Long subscriptionId, Long adminId);
    List<PackageSubscription> getByOwner(Long ownerId);
}
