package com.stayhub.api.service;

import com.stayhub.api.entity.ServicePool;
import java.util.List;
import java.util.Map;

public interface ServicePoolService {

    ServicePool createPool(ServicePool pool);

    ServicePool updatePoolAmount(Long poolId, Double totalAmount);

    void assignRoomToPool(Long roomId, Long poolId);

    void removeRoomFromPool(Long roomId, Long poolId);

    List<ServicePool> getPoolsByBranch(Long branchId);

    List<ServicePool> getPoolsByRoom(Long roomId);

    /**
     * Tinh phi phai tra cho 1 phong tu 1 pool cu the trong thang nay.
     */
    double calculateRoomShareForPool(Long roomId, Long poolId, int membersInRoom);

    /**
     * Tinh phi phai tra cho tat ca pool ma phong dang tham gia
     * Tra ve danh sach json: [{poolName: "", totalAmount: 1000, allocationMethod: "", divisor: 1, myShare: 1000}]
     */
    List<Map<String, Object>> calculateAllSharedServicesForRoom(Long roomId);
}
