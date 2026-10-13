package com.stayhub.api.repository;

import com.stayhub.api.entity.VoucherRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VoucherRoomRepository extends JpaRepository<VoucherRoom, Long> {

    List<VoucherRoom> findByVoucherId(Long voucherId);
    
    List<VoucherRoom> findByRoomId(Long roomId);

    List<VoucherRoom> findByRoomIdIn(List<Long> roomIds);
}
