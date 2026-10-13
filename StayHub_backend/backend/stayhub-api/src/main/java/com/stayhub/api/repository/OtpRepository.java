package com.stayhub.api.repository;

import com.stayhub.api.entity.Otp;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface OtpRepository extends JpaRepository<Otp, Long> {

    @Query("""
        SELECT o FROM Otp o
        WHERE o.target = :target
          AND o.code = :code
          AND o.type = :type
          AND o.usedAt IS NULL
          AND o.expiresAt > :now
        ORDER BY o.createdAt DESC
        LIMIT 1
    """)
    Optional<Otp> findValidOtp(
            @Param("target") String target,
            @Param("code") String code,
            @Param("type") Otp.OtpType type,
            @Param("now") LocalDateTime now
    );
}