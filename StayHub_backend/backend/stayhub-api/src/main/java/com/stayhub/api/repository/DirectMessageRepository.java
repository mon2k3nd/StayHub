package com.stayhub.api.repository;

import com.stayhub.api.entity.DirectMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DirectMessageRepository extends JpaRepository<DirectMessage, Long> {
    List<DirectMessage> findByRoomIdOrderByCreatedAtAsc(Long roomId);
}
