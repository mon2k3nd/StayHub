package com.stayhub.api.repository;

import com.stayhub.api.entity.SmartDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SmartDeviceRepository extends JpaRepository<SmartDevice, Long> {
    List<SmartDevice> findByRoomId(Long roomId);
    Optional<SmartDevice> findByIdAndRoomId(Long id, Long roomId);
}
