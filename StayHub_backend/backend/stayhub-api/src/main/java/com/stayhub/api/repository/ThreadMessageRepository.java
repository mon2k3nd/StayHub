package com.stayhub.api.repository;

import com.stayhub.api.entity.ThreadMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ThreadMessageRepository extends JpaRepository<ThreadMessage, Long> {
    List<ThreadMessage> findByThreadIdOrderByCreatedAtAsc(Long threadId);
}
