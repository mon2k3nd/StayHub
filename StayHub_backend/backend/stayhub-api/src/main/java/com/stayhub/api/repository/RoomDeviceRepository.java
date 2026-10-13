package com.stayhub.api.repository;

import com.stayhub.api.entity.RoomDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface RoomDeviceRepository extends JpaRepository<RoomDevice, Long> {
    List<RoomDevice> findByRoomId(Long roomId);
}
