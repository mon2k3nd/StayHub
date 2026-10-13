package com.stayhub.api.repository;

import com.stayhub.api.entity.MarketplacePost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MarketplacePostRepository extends JpaRepository<MarketplacePost, Long> {
    List<MarketplacePost> findAllByStatusOrderByCreatedAtDesc(String status);
}
