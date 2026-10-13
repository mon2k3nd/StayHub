package com.stayhub.api.service;

import org.springframework.stereotype.Service;
import lombok.Getter;

@Service
public class AddressMapper {

    /**
     * Map địa chỉ 4 cấp về 3 cấp theo chuẩn sáp nhập hành chính 2026.
     * Lớp Legal & Core Business (eKYC/Hợp đồng/Hóa đơn) tuân thủ cấu trúc 3 cấp mới:
     * Số nhà/Đường, Phường/Xã, Tỉnh/Thành phố - lược bỏ hoàn toàn cấp Quận/Huyện.
     * 
     * @param address4Tier định dạng "Số nhà/Đường, Phường/Xã, Quận/Huyện, Tỉnh/Thành phố"
     * @return Address3Tier chứa thông tin đã được nội suy và map về 3 cấp.
     */
    public static Address3Tier mapTo3Tier(String address4Tier) {
        if (address4Tier == null || address4Tier.trim().isEmpty()) {
            return new Address3Tier("", "", "");
        }
        
        String[] parts = address4Tier.split(",");
        for (int i = 0; i < parts.length; i++) {
            parts[i] = parts[i].trim();
        }
        
        if (parts.length < 4) {
            // Nếu không đủ 4 cấp (có thể chuỗi bị thiếu do nhập sai),
            // ta cố gắng fallback bằng cách giữ nguyên raw data.
            return new Address3Tier(address4Tier, "", "");
        }
        
        String province = parts[parts.length - 1];
        // Bỏ Quận/Huyện (parts.length - 2)
        String ward = parts[parts.length - 3];
        
        // Phần còn lại nối lại làm Số nhà/Đường (phòng khi Số nhà/Đường có dấu phẩy)
        StringBuilder streetBuilder = new StringBuilder();
        for (int i = 0; i < parts.length - 3; i++) {
            streetBuilder.append(parts[i]);
            if (i < parts.length - 4) {
                streetBuilder.append(", ");
            }
        }
        
        return new Address3Tier(streetBuilder.toString(), ward, province);
    }
    
    @Getter
    public static class Address3Tier {
        private final String street;
        private final String ward;
        private final String province;
        
        public Address3Tier(String street, String ward, String province) {
            this.street = street;
            this.ward = ward;
            this.province = province;
        }
        
        public String toFullAddress() {
            if (ward.isEmpty() && province.isEmpty()) return street;
            return street + ", " + ward + ", " + province;
        }
    }
}
