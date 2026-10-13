package com.stayhub.api.repository;

import com.stayhub.api.entity.CashSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CashSessionRepository extends JpaRepository<CashSession, Long> {
    Optional<CashSession> findBySessionId(String sessionId);

    java.util.List<CashSession> findByBranchId(Long branchId);

    /**
     * Kiểm tra {@code sessionId} đã tồn tại chưa, KỂ CẢ phiên đã xoá mềm.
     *
     * <p>{@code cash_sessions.session_id} có UNIQUE INDEX ở tầng DB và KHÔNG
     * phải partial index — nó chặn cả dòng đã xoá mềm. Dùng native query để bỏ
     * qua {@code @SQLRestriction} khi tính hậu tố {@code _OFF_<id>} an toàn.</p>
     */
    @org.springframework.data.jpa.repository.Query(
            value = "SELECT COUNT(*) > 0 FROM cash_sessions WHERE session_id = :sessionId",
            nativeQuery = true)
    boolean existsBySessionIdIncludingDeleted(
            @org.springframework.data.repository.query.Param("sessionId") String sessionId);

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("SELECT c FROM CashSession c WHERE c.sessionId = :sessionId")
    Optional<CashSession> findBySessionIdWithLock(@org.springframework.data.repository.query.Param("sessionId") String sessionId);
}
