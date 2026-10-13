package com.stayhub.api.service;

import com.stayhub.api.dto.response.GlobalSearchResponse;
import com.stayhub.api.entity.Contract;
import com.stayhub.api.entity.Room;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SearchService {

    private final RoomRepository roomRepository;
    private final ContractRepository contractRepository;
    private final UserRepository userRepository;

    public GlobalSearchResponse globalSearch(Long ownerId, String query) {
        String q = query == null ? "" : query.toLowerCase().trim();

        List<GlobalSearchResponse.TenantSearchResult> tenantResults = new ArrayList<>();
        List<GlobalSearchResponse.RoomSearchResult> roomResults = new ArrayList<>();

        if (q.isEmpty()) {
            return new GlobalSearchResponse(tenantResults, roomResults);
        }

        // 1. Search Rooms by name
        List<Room> allRooms = roomRepository.findByOwnerId(ownerId);
        for (Room room : allRooms) {
            if (room.getRoomName() != null && room.getRoomName().toLowerCase().contains(q)) {
                roomResults.add(GlobalSearchResponse.RoomSearchResult.builder()
                        .id(room.getId())
                        .name(room.getRoomName())
                        .status(room.getStatus() != null ? room.getStatus().name() : "")
                        .build());
            }
        }

        // 2. Search Tenants and Contracts
        List<Contract> allContracts = contractRepository.findByOwnerId(ownerId);
        
        Set<Long> processedTenantIds = new HashSet<>();

        for (Contract contract : allContracts) {
            if (contract.getTenantId() == null) continue;

            Optional<User> userOpt = userRepository.findById(contract.getTenantId());
            if (userOpt.isEmpty()) continue;

            User tenant = userOpt.get();
            String name = tenant.getName() != null ? tenant.getName() : "";
            String phone = tenant.getPhoneNumber() != null ? tenant.getPhoneNumber() : "";
            String cccd = (tenant.getTenantProfile() != null && tenant.getTenantProfile().getCccdNumber() != null)
                    ? tenant.getTenantProfile().getCccdNumber() : "";

            boolean matchesTenant = name.toLowerCase().contains(q) || 
                                    phone.toLowerCase().contains(q) || 
                                    cccd.toLowerCase().contains(q);

            Room room = roomRepository.findById(contract.getRoomId()).orElse(null);
            String roomName = room != null ? room.getRoomName() : "";

            if (matchesTenant && !processedTenantIds.contains(tenant.getId())) {
                tenantResults.add(GlobalSearchResponse.TenantSearchResult.builder()
                        .id(tenant.getId())
                        .name(name)
                        .phone(phone)
                        .cccd(cccd)
                        .roomId(contract.getRoomId())
                        .roomName(roomName)
                        .build());
                processedTenantIds.add(tenant.getId());
            }

            // Also search contract by room name or contract ID if we want
            if (roomName.toLowerCase().contains(q)) {
                // Check if already added in room search
                boolean alreadyAdded = roomResults.stream().anyMatch(r -> r.getId().equals(contract.getRoomId()));
                if (!alreadyAdded) {
                    roomResults.add(GlobalSearchResponse.RoomSearchResult.builder()
                            .id(contract.getRoomId())
                            .name(roomName)
                            .status(room != null && room.getStatus() != null ? room.getStatus().name() : "")
                            .contractId(contract.getId())
                            .tenantName(name)
                            .build());
                } else {
                    // Update existing room with contract info
                    for (GlobalSearchResponse.RoomSearchResult r : roomResults) {
                        if (r.getId().equals(contract.getRoomId())) {
                            r.setContractId(contract.getId());
                            r.setTenantName(name);
                        }
                    }
                }
            }
        }

        return new GlobalSearchResponse(tenantResults, roomResults);
    }
}
