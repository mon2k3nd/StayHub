package com.stayhub.api.service;

import com.stayhub.api.dto.response.AddressResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
@Slf4j
@RequiredArgsConstructor
public class AddressService {

    private final WebClient webClient = WebClient.builder().baseUrl("https://esgoo.net").build();

    // Simple in-memory cache to avoid spamming Esgoo
    private final Map<String, List<AddressResponse>> cache = new ConcurrentHashMap<>();

    public List<AddressResponse> getProvinces() {
        String cacheKey = "provinces";
        if (cache.containsKey(cacheKey)) {
            return cache.get(cacheKey);
        }

        try {
            Map<String, Object> response = webClient.get()
                    .uri("/api-tinhthanh/1/0.htm")
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();

            if (response != null && response.containsKey("data")) {
                List<Map<String, Object>> data = (List<Map<String, Object>>) response.get("data");
                List<AddressResponse> results = data.stream().map(item -> {
                    AddressResponse dto = mapToDto(item);
                    // Embed new34 mapping logic here
                    dto.setNew34Mapping(AddressData.getNew34ByEsgooId(dto.getId()));
                    return dto;
                }).collect(Collectors.toList());
                
                cache.put(cacheKey, results);
                return results;
            }
        } catch (Exception e) {
            log.error("Failed to fetch provinces from esgoo", e);
        }
        return new ArrayList<>();
    }

    public List<AddressResponse> getDistricts(String provinceId) {
        String cacheKey = "districts_" + provinceId;
        if (cache.containsKey(cacheKey)) {
            return cache.get(cacheKey);
        }

        try {
            Map<String, Object> response = webClient.get()
                    .uri("/api-tinhthanh/2/{id}.htm", provinceId)
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();

            if (response != null && response.containsKey("data")) {
                List<Map<String, Object>> data = (List<Map<String, Object>>) response.get("data");
                List<AddressResponse> results = data.stream().map(this::mapToDto).collect(Collectors.toList());
                cache.put(cacheKey, results);
                return results;
            }
        } catch (Exception e) {
            log.error("Failed to fetch districts from esgoo", e);
        }
        return new ArrayList<>();
    }

    public List<AddressResponse> getWards(String districtId) {
        String cacheKey = "wards_" + districtId;
        if (cache.containsKey(cacheKey)) {
            return cache.get(cacheKey);
        }

        try {
            Map<String, Object> response = webClient.get()
                    .uri("/api-tinhthanh/3/{id}.htm", districtId)
                    .retrieve()
                    .bodyToMono(new ParameterizedTypeReference<Map<String, Object>>() {})
                    .block();

            if (response != null && response.containsKey("data")) {
                List<Map<String, Object>> data = (List<Map<String, Object>>) response.get("data");
                List<AddressResponse> results = data.stream().map(this::mapToDto).collect(Collectors.toList());
                cache.put(cacheKey, results);
                return results;
            }
        } catch (Exception e) {
            log.error("Failed to fetch wards from esgoo", e);
        }
        return new ArrayList<>();
    }

    private AddressResponse mapToDto(Map<String, Object> item) {
        return AddressResponse.builder()
                .id(item.get("id") != null ? item.get("id").toString() : null)
                .name(item.get("name") != null ? item.get("name").toString() : null)
                .nameEn(item.get("name_en") != null ? item.get("name_en").toString() : null)
                .fullName(item.get("full_name") != null ? item.get("full_name").toString() : null)
                .fullNameEn(item.get("full_name_en") != null ? item.get("full_name_en").toString() : null)
                .latitude(item.get("latitude") != null ? item.get("latitude").toString() : null)
                .longitude(item.get("longitude") != null ? item.get("longitude").toString() : null)
                .build();
    }
}
