package com.stayhub.api.service;

import com.stayhub.api.entity.SystemFeatureFlag;
import com.stayhub.api.repository.FeatureFlagRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FeatureFlagService {
    private final FeatureFlagRepository featureFlagRepository;

    public Map<String, Boolean> getAllFeatureFlags() {
        List<SystemFeatureFlag> flags = featureFlagRepository.findAll();
        return flags.stream().collect(Collectors.toMap(
            SystemFeatureFlag::getFeatureKey,
            SystemFeatureFlag::isEnabled
        ));
    }

    public boolean isFeatureEnabled(String key) {
        return featureFlagRepository.findById(key)
                .map(SystemFeatureFlag::isEnabled)
                .orElse(false);
    }

    public SystemFeatureFlag updateFeatureFlag(String key, boolean isEnabled) {
        SystemFeatureFlag flag = featureFlagRepository.findById(key)
                .orElseGet(() -> {
                    SystemFeatureFlag newFlag = new SystemFeatureFlag();
                    newFlag.setFeatureKey(key);
                    newFlag.setDescription("Feature flag for " + key);
                    return newFlag;
                });
        flag.setEnabled(isEnabled);
        return featureFlagRepository.save(flag);
    }
}
