package com.stayhub.api.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AddressResponse {
    private String id;
    private String name;
    private String nameEn;
    private String fullName;
    private String fullNameEn;
    private String latitude;
    private String longitude;
    
    // For Provinces, to support Dual Address mapping
    private Map<String, Object> new34Mapping;
}
