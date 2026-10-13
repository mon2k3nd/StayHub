package com.stayhub.api.repository;

import com.stayhub.api.entity.RoomAsset;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface RoomAssetRepository extends JpaRepository<RoomAsset, Long> {
    List<RoomAsset> findByRoomId(Long roomId);
}
