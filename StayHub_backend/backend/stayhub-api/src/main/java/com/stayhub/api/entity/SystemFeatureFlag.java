package com.stayhub.api.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "system_feature_flags")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SystemFeatureFlag {
    @Id
    @Column(name = "feature_key", nullable = false, length = 100)
    private String featureKey;

    @Column(name = "is_enabled", nullable = false)
    private boolean isEnabled;

    @Column(name = "description")
    private String description;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public String getFeatureKey() { return featureKey; }
    public void setFeatureKey(String featureKey) { this.featureKey = featureKey; }
    
    public boolean isEnabled() { return isEnabled; }
    public void setEnabled(boolean enabled) { this.isEnabled = enabled; }
    
    public void setDescription(String description) { this.description = description; }
}
