package com.stayhub.api.repository;

import com.stayhub.api.entity.RoomServicePool;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface RoomServicePoolRepository extends JpaRepository<RoomServicePool, Long> {
    List<RoomServicePool> findByRoomId(Long roomId);
    List<RoomServicePool> findByPoolId(Long poolId);
}
