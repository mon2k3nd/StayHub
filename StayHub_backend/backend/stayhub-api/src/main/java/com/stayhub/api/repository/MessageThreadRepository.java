package com.stayhub.api.repository;

import com.stayhub.api.entity.MessageThread;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface MessageThreadRepository extends JpaRepository<MessageThread, Long> {
    
    @Query("SELECT mt FROM MessageThread mt WHERE mt.userId1 = :userId OR mt.userId2 = :userId ORDER BY mt.updatedAt DESC")
    List<MessageThread> findByUserId(Long userId);

    @Query("SELECT mt FROM MessageThread mt WHERE (mt.userId1 = :user1 AND mt.userId2 = :user2) OR (mt.userId1 = :user2 AND mt.userId2 = :user1)")
    List<MessageThread> findByUserPair(Long user1, Long user2);
}
