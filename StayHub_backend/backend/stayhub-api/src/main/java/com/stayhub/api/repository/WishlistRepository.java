package com.stayhub.api.repository;

import com.stayhub.api.entity.Wishlist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface WishlistRepository extends JpaRepository<Wishlist, Long> {

    List<Wishlist> findByUserIdOrderByCreatedAtDesc(Long userId);

    Optional<Wishlist> findByUserIdAndRoomId(Long userId, Long roomId);

    boolean existsByUserIdAndRoomId(Long userId, Long roomId);

    void deleteByUserIdAndRoomId(Long userId, Long roomId);

    // Tìm tất cả user đã lưu phòng này (để gửi thông báo khi phòng trống)
    List<Wishlist> findByRoomId(Long roomId);

    long countByRoomId(Long roomId);

    @org.springframework.data.jpa.repository.Query("SELECT w.roomId, COUNT(w) FROM Wishlist w WHERE w.roomId IN :roomIds GROUP BY w.roomId")
    List<Object[]> countWishlistsByRoomIdIn(@org.springframework.data.repository.query.Param("roomIds") List<Long> roomIds);

    long countByUserId(Long userId);
}
