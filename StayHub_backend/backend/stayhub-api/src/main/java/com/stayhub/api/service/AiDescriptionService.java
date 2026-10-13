package com.stayhub.api.service;

import com.stayhub.api.entity.Room;
import com.stayhub.api.repository.RoomRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class AiDescriptionService {

    private final RoomRepository roomRepository;

    public String generateDescription(Long roomId, String tone) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Room not found"));

        // Extract real data
        double price = room.getPrice() != null ? room.getPrice() : 0;
        double area = room.getFloorArea() != null ? room.getFloorArea() : 0;
        String roomType = "Phòng trọ"; // roomType không có trong entity, mặc định là phòng trọ

        // In a real production scenario, you would call OpenAI API here
        // String prompt = "Viết đoạn mô tả phòng " + roomType + " rộng " + area + "m2 giá " + price + " VND. Văn phong: " + tone;
        // return openAiClient.generate(prompt);

        // For now, we simulate the AI logic on the backend with real data
        String formattedPrice = String.format("%,.0f", price).replace(",", ".") + "đ";
        
        switch (tone.toUpperCase()) {
            case "CHUYEN_NGHIEP":
                return "Cho thuê " + roomType.toLowerCase() + " cao cấp, diện tích " + area + "m². Giá thuê: " + formattedPrice + "/tháng. " +
                       "Phòng được trang bị đầy đủ nội thất hiện đại, không gian sống an ninh, yên tĩnh. Phù hợp cho người đi làm hoặc gia đình nhỏ cần môi trường sống chất lượng.";
            case "THU_HUT_SINH_VIEN":
                return "🔥 CỰC SỐC! " + roomType + " siêu xịn " + area + "m² giá chỉ " + formattedPrice + "!\n" +
                       "Vị trí đắc địa gần trường đại học, khu vực an ninh. Tiện ích ngập tràn, giờ giấc tự do thoải mái. Nhanh tay chốt ngay kẻo lỡ các bạn ơi!";
            case "AM_CUNG_GIA_DINH":
                return "Tổ ấm " + area + "m² tuyệt vời dành cho gia đình bạn với mức giá " + formattedPrice + "/tháng.\n" +
                       "Không gian thiết kế ấm cúng, an toàn cho trẻ nhỏ. Khu dân cư văn minh, thân thiện. Nơi lý tưởng để xây dựng những kỷ niệm gia đình đáng nhớ.";
            case "TOI_GIAN_MODERN":
                return roomType + " " + area + "m² thiết kế tối giản, hiện đại. Giá: " + formattedPrice + ".\n" +
                       "Không gian mở, tối ưu ánh sáng tự nhiên. Tiện nghi cơ bản đầy đủ, đề cao sự tinh tế và gọn gàng. Phù hợp lối sống Minimalist.";
            case "NGAN_GON":
                return "Cho thuê " + roomType.toLowerCase() + " " + area + "m². Giá " + formattedPrice + ". " +
                       "Đủ đồ, dọn vào ở ngay. An ninh 24/7. Liên hệ để xem phòng.";
            default:
                return "Cho thuê " + roomType.toLowerCase() + " diện tích " + area + "m² với mức giá " + formattedPrice + ". Vui lòng liên hệ để biết thêm chi tiết.";
        }
    }
}
