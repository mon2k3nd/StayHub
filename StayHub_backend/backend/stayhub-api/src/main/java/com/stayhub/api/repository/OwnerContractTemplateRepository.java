package com.stayhub.api.repository;

import com.stayhub.api.entity.OwnerContractTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OwnerContractTemplateRepository extends JpaRepository<OwnerContractTemplate, Long> {
}
