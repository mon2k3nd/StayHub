package com.stayhub.api.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GlobalSearchResponse {
    private List<TenantSearchResult> tenants;
    private List<RoomSearchResult> roomsAndContracts;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TenantSearchResult {
        private Long id;
        private String name;
        private String phone;
        private String cccd;
        private Long roomId;
        private String roomName;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class RoomSearchResult {
        private Long id;
        private String name;
        private String status;
        private Long contractId;
        private String tenantName;
    }
}
