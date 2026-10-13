package com.stayhub.api.repository;

import com.stayhub.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByPhoneNumber(String phoneNumber);
    Optional<User> findByEmail(String email);
    boolean existsByPhoneNumber(String phoneNumber);
    boolean existsByEmail(String email);
    long countByRoleId(String roleId);
    java.util.List<User> findByRoleId(String roleId);

    @org.springframework.data.jpa.repository.Query("SELECT DISTINCT u FROM User u " +
            "LEFT JOIN u.tenantProfile tp " +
            "WHERE LOWER(u.phoneNumber) LIKE LOWER(CONCAT('%', :query, '%')) " +
            "OR LOWER(u.name) LIKE LOWER(CONCAT('%', :query, '%')) " +
            "OR LOWER(tp.cccdNumber) LIKE LOWER(CONCAT('%', :query, '%'))")
    java.util.List<User> findByOmniQuery(@org.springframework.data.repository.query.Param("query") String query);

    @org.springframework.data.jpa.repository.Query(value = "SELECT * FROM users WHERE role_id = 'OWNER' OR account_status = 'PENDING_OWNER_APPROVAL'", nativeQuery = true)
    java.util.List<User> findOwners();

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Query(value = "UPDATE owner_profiles SET package_id = 'FREE' WHERE expired_at < NOW()", nativeQuery = true)
    int downgradeExpiredPackages();

    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    @org.springframework.data.jpa.repository.Query(value = "UPDATE owner_profiles SET package_id = :packageId, expired_at = NOW() + CAST('14 days' AS INTERVAL) WHERE user_id = :userId", nativeQuery = true)
    int approveOwnerProfile(@org.springframework.data.repository.query.Param("packageId") String packageId, @org.springframework.data.repository.query.Param("userId") Long userId);
}