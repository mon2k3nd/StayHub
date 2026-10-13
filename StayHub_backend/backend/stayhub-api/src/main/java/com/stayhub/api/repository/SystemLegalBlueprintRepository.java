package com.stayhub.api.repository;

import com.stayhub.api.entity.SystemLegalBlueprint;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SystemLegalBlueprintRepository extends JpaRepository<SystemLegalBlueprint, Long> {
    Optional<SystemLegalBlueprint> findByStatus(String status);
}
