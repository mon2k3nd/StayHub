package com.stayhub.api.repository;

import com.stayhub.api.entity.DirectChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DirectChatMessageRepository extends JpaRepository<DirectChatMessage, Long> {
    
    @Query("SELECT m FROM DirectChatMessage m WHERE " +
           "(m.senderId = :user1Id AND m.receiverId = :user2Id) OR " +
           "(m.senderId = :user2Id AND m.receiverId = :user1Id) " +
           "ORDER BY m.createdAt ASC")
    List<DirectChatMessage> findChatHistory(@Param("user1Id") Long user1Id, @Param("user2Id") Long user2Id);
}
