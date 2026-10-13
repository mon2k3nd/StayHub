package com.stayhub.api.repository;

import com.stayhub.api.entity.InspectionItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface InspectionItemRepository extends JpaRepository<InspectionItem, Long> {
    List<InspectionItem> findByInspectionId(Long inspectionId);
}
