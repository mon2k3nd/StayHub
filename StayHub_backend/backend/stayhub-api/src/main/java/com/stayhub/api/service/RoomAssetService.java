package com.stayhub.api.service;

import com.stayhub.api.entity.RoomAsset;
import java.util.List;

public interface RoomAssetService {
    List<RoomAsset> getByRoom(Long roomId);
    RoomAsset create(RoomAsset asset);
    RoomAsset update(Long id, RoomAsset asset);
    void delete(Long id);
}
