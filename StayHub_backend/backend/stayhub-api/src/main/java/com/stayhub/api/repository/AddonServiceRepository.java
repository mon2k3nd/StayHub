package com.stayhub.api.repository;

import com.stayhub.api.entity.AddonService;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AddonServiceRepository extends JpaRepository<AddonService, Long> {
    List<AddonService> findByOwnerIdAndIsActiveTrue(Long ownerId);
}
