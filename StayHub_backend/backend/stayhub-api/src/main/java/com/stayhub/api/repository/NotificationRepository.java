package com.stayhub.api.repository;

import com.stayhub.api.entity.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByReceiverIdAndIsDeletedFalseOrderByCreatedAtDesc(Long receiverId);
    List<Notification> findBySenderIdAndIsDeletedFalseOrderByCreatedAtDesc(Long senderId);
    List<Notification> findByReceiverIdAndIsReadFalseAndIsDeletedFalse(Long receiverId);
    @org.springframework.data.jpa.repository.Query("SELECT COUNT(n) FROM Notification n WHERE n.receiverId = :userId AND n.isRead = false AND n.isDeleted = false")
    long countUnreadNotifications(@org.springframework.data.repository.query.Param("userId") Long userId);
}
