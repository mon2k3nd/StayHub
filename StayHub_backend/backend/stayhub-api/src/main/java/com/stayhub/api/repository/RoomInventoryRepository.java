package com.stayhub.api.repository;

import com.stayhub.api.entity.RoomInventory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoomInventoryRepository extends JpaRepository<RoomInventory, Long> {

    List<RoomInventory> findByRoomId(Long roomId);

    List<RoomInventory> findByBranchId(Long branchId);

    List<RoomInventory> findByRoomIdIn(List<Long> roomIds);

    void deleteByRoomId(Long roomId);
}
