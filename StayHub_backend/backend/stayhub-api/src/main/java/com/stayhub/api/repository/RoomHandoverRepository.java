package com.stayhub.api.repository;

import com.stayhub.api.entity.RoomHandover;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface RoomHandoverRepository extends JpaRepository<RoomHandover, Long> {
    List<RoomHandover> findByRoomId(Long roomId);
    List<RoomHandover> findByContractId(Long contractId);
}
