package com.stayhub.api.service.impl;

import com.stayhub.api.entity.RoomServicePool;
import com.stayhub.api.entity.ServicePool;
import com.stayhub.api.repository.RoomMemberRepository;
import com.stayhub.api.repository.RoomServicePoolRepository;
import com.stayhub.api.repository.ServicePoolRepository;
import com.stayhub.api.service.ServicePoolService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
public class ServicePoolServiceImpl implements ServicePoolService {

    private final ServicePoolRepository servicePoolRepository;
    private final RoomServicePoolRepository roomServicePoolRepository;
    private final RoomMemberRepository roomMemberRepository;

    @Override
    @Transactional
    public ServicePool createPool(ServicePool pool) {
        return servicePoolRepository.save(pool);
    }

    @Override
    @Transactional
    public ServicePool updatePoolAmount(Long poolId, Double totalAmount) {
        ServicePool pool = servicePoolRepository.findById(poolId)
                .orElseThrow(() -> new RuntimeException("ServicePool not found: " + poolId));
        pool.setPrice(totalAmount);
        return servicePoolRepository.save(pool);
    }

    @Override
    @Transactional
    public void assignRoomToPool(Long roomId, Long poolId) {
        boolean alreadyAssigned = roomServicePoolRepository.findByRoomId(roomId)
                .stream().anyMatch(rsp -> rsp.getPoolId().equals(poolId));
        if (!alreadyAssigned) {
            roomServicePoolRepository.save(
                    RoomServicePool.builder().roomId(roomId).poolId(poolId).build());
            log.info("Room {} assigned to pool {}", roomId, poolId);
        }
    }

    @Override
    @Transactional
    public void removeRoomFromPool(Long roomId, Long poolId) {
        roomServicePoolRepository.findByRoomId(roomId).stream()
                .filter(rsp -> rsp.getPoolId().equals(poolId))
                .forEach(rsp -> roomServicePoolRepository.deleteById(rsp.getId()));
    }

    @Override
    public List<ServicePool> getPoolsByBranch(Long branchId) {
        return servicePoolRepository.findByBranchId(branchId);
    }

    @Override
    public List<ServicePool> getPoolsByRoom(Long roomId) {
        List<Long> poolIds = roomServicePoolRepository.findByRoomId(roomId)
                .stream().map(RoomServicePool::getPoolId).collect(Collectors.toList());
        return servicePoolRepository.findAllById(poolIds);
    }

    @Override
    public double calculateRoomShareForPool(Long roomId, Long poolId, int membersInRoom) {
        ServicePool pool = servicePoolRepository.findById(poolId)
                .orElseThrow(() -> new RuntimeException("ServicePool not found: " + poolId));

        double total = pool.getPrice() != null ? pool.getPrice() : 0.0;
        String method = pool.getAllocationMethod();

        switch (method) {
            case "FLAT_PER_ROOM":
                // Gia co dinh moi phong phai tra
                return total;

            case "FLAT_PER_TENANT":
                // Don gia x so nguoi trong phong
                return total * membersInRoom;

            case "SHARED_EQUAL_ROOM": {
                // Chia deu cho tat ca cac phong trong pool
                long roomsInPool = roomServicePoolRepository.findByPoolId(poolId).size();
                if (roomsInPool == 0) return 0;
                return total / roomsInPool;
            }

            case "SHARED_EQUAL_HEAD": {
                // Chia theo ti le dau nguoi
                List<Long> allRoomIds = roomServicePoolRepository.findByPoolId(poolId)
                        .stream().map(RoomServicePool::getRoomId).collect(Collectors.toList());
                int totalMembers = allRoomIds.stream()
                        .mapToInt(rid -> roomMemberRepository.findByRoomId(rid).size())
                        .sum();
                if (totalMembers == 0) {
                    return allRoomIds.isEmpty() ? 0 : total / allRoomIds.size();
                }
                return total * ((double) membersInRoom / totalMembers);
            }

            case "METERED":
                // METERED duoc tinh rieng tu chi so dong ho
                return 0;

            default:
                log.warn("Unknown allocation method: {} for pool: {}", method, poolId);
                return 0;
        }
    }

    @Override
    public List<Map<String, Object>> calculateAllSharedServicesForRoom(Long roomId) {
        List<Map<String, Object>> result = new java.util.ArrayList<>();
        List<ServicePool> pools = getPoolsByRoom(roomId);

        int membersInRoom = roomMemberRepository.findByRoomId(roomId).size();
        if (membersInRoom == 0) membersInRoom = 1; // Fallback: toi thieu 1 nguoi

        for (ServicePool pool : pools) {
            double total = pool.getPrice() != null ? pool.getPrice() : 0.0;
            String method = pool.getAllocationMethod();
            double myShare = 0;
            double divisor = 1; // Can be total rooms or total members

            switch (method) {
                case "FLAT_PER_ROOM":
                    myShare = total;
                    break;
                case "FLAT_PER_TENANT":
                    divisor = membersInRoom;
                    myShare = total * membersInRoom;
                    break;
                case "SHARED_EQUAL_ROOM":
                    long roomsInPool = roomServicePoolRepository.findByPoolId(pool.getId()).size();
                    if (roomsInPool > 0) {
                        divisor = roomsInPool;
                        myShare = total / roomsInPool;
                    }
                    break;
                case "SHARED_EQUAL_HEAD":
                    List<Long> allRoomIds = roomServicePoolRepository.findByPoolId(pool.getId())
                            .stream().map(RoomServicePool::getRoomId).collect(Collectors.toList());
                    int totalMembers = allRoomIds.stream()
                            .mapToInt(rid -> roomMemberRepository.findByRoomId(rid).size())
                            .sum();
                    if (totalMembers == 0) {
                        divisor = allRoomIds.size();
                        myShare = allRoomIds.isEmpty() ? 0 : total / allRoomIds.size();
                    } else {
                        divisor = totalMembers;
                        myShare = total * ((double) membersInRoom / totalMembers);
                    }
                    break;
                default:
                    myShare = 0;
            }

            Map<String, Object> poolDetail = new java.util.HashMap<>();
            poolDetail.put("poolName", pool.getName());
            poolDetail.put("totalAmount", total);
            poolDetail.put("allocationMethod", method);
            poolDetail.put("divisor", divisor);
            poolDetail.put("myShare", myShare);
            result.add(poolDetail);

            log.info("Pool [{}] - Method [{}] - Room {}: {} VND",
                    pool.getName(), pool.getAllocationMethod(), roomId, myShare);
        }
        return result;
    }
}
