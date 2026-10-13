package com.stayhub.api.controller;

import com.stayhub.api.dto.response.AddressResponse;
import com.stayhub.api.service.AddressService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/addresses")
@RequiredArgsConstructor
public class V1AddressController {

    private final AddressService addressService;

    @GetMapping("/provinces")
    public ResponseEntity<List<AddressResponse>> getProvinces() {
        return ResponseEntity.ok(addressService.getProvinces());
    }

    @GetMapping("/districts/{provinceId}")
    public ResponseEntity<List<AddressResponse>> getDistricts(@PathVariable String provinceId) {
        return ResponseEntity.ok(addressService.getDistricts(provinceId));
    }

    @GetMapping("/wards/{districtId}")
    public ResponseEntity<List<AddressResponse>> getWards(@PathVariable String districtId) {
        return ResponseEntity.ok(addressService.getWards(districtId));
    }
}
