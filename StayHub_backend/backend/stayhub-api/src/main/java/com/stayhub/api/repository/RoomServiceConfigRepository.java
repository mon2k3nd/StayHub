package com.stayhub.api.repository;

import com.stayhub.api.entity.RoomServiceConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface RoomServiceConfigRepository extends JpaRepository<RoomServiceConfig, Long> {
    List<RoomServiceConfig> findByRoomId(Long roomId);
    void deleteByRoomId(Long roomId);
}
