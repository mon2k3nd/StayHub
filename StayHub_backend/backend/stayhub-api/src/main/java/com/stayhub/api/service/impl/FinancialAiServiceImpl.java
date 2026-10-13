package com.stayhub.api.service.impl;

import com.stayhub.api.entity.Bill;
import com.stayhub.api.entity.Expense;
import com.stayhub.api.entity.Room;
import com.stayhub.api.repository.BillRepository;
import com.stayhub.api.repository.ExpenseRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.service.FinancialAiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class FinancialAiServiceImpl implements FinancialAiService {

    private final BillRepository billRepository;
    private final ExpenseRepository expenseRepository;
    private final RoomRepository roomRepository;

    @Value("${gemini.api.key:mock_key}")
    private String geminiApiKey;

    @Override
    public String getFinancialAdvice(Long ownerId, Integer month, Integer year) {
        // 1. Thu thập dữ liệu tổng hợp (không chứa thông tin cá nhân)
        int targetMonth = month != null ? month : LocalDate.now().getMonthValue();
        int targetYear = year != null ? year : LocalDate.now().getYear();

        List<Room> rooms = roomRepository.findByOwnerId(ownerId);
        long totalRooms = rooms.size();
        long rentedRooms = rooms.stream().filter(r -> "DA_THUE".equals(r.getStatus() != null ? r.getStatus().name() : "")).count();
        long emptyRooms = rooms.stream().filter(r -> "TRONG".equals(r.getStatus() != null ? r.getStatus().name() : "")).count();
        double occupancyRate = totalRooms > 0 ? (rentedRooms * 100.0 / totalRooms) : 0;

        // Tổng doanh thu kỳ này (từ hóa đơn đã thanh toán)
        List<Bill> bills = billRepository.findPaidByMonthYear(targetMonth, targetYear);
        double totalRevenue = bills.stream()
                .filter(b -> {
                    // Chỉ tính hóa đơn của chủ nhà này (join với room)
                    return rooms.stream().anyMatch(r -> r.getId().equals(b.getRoomId()));
                })
                .mapToDouble(b -> b.getTotalAmount() != null ? b.getTotalAmount() : 0)
                .sum();

        // Tổng chi phí kỳ này
        List<Expense> expenses = expenseRepository.findByOwnerIdAndMonthAndYear(ownerId, targetMonth, targetYear);
        double totalExpense = expenses.stream().mapToDouble(e -> e.getAmount() != null ? e.getAmount() : 0).sum();

        double netProfit = totalRevenue - totalExpense;

        // 2. Build Prompt (an toàn, không chứa thông tin cá nhân)
        String prompt = String.format(
                "Bạn là chuyên gia tư vấn kinh doanh bất động sản cho thuê tại Việt Nam. " +
                "Hãy phân tích dữ liệu tháng %d/%d của một dãy trọ và đưa ra lời khuyên ngắn gọn, thực tế (tối đa 300 từ, định dạng Markdown):\n\n" +
                "- Tổng số phòng: %d\n" +
                "- Số phòng đang cho thuê: %d\n" +
                "- Số phòng trống: %d\n" +
                "- Tỷ lệ lấp đầy: %.1f%%\n" +
                "- Tổng doanh thu thu được: %,.0f VNĐ\n" +
                "- Tổng chi phí vận hành: %,.0f VNĐ\n" +
                "- Lợi nhuận ròng: %,.0f VNĐ\n\n" +
                "Hãy nhận xét và đề xuất 2-3 hành động cụ thể nhất để tối ưu doanh thu/chi phí cho tháng tới.",
                targetMonth, targetYear,
                totalRooms, rentedRooms, emptyRooms, occupancyRate,
                totalRevenue, totalExpense, netProfit
        );

        // 3. Nếu không có API key thực, trả về mock data có ý nghĩa
        if ("mock_key".equals(geminiApiKey)) {
            return generateMockAdvice(totalRooms, emptyRooms, occupancyRate, netProfit);
        }

        // 4. Gọi Gemini API thực (blocking vì đây là endpoint không phải reactive)
        try {
            WebClient webClient = WebClient.builder().build();
            String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=" + geminiApiKey;

            Map<String, Object> requestBody = Map.of(
                    "contents", new Object[]{
                            Map.of("parts", new Object[]{
                                    Map.of("text", prompt)
                            })
                    }
            );

            @SuppressWarnings("unchecked")
            Map<String, Object> response = webClient.post()
                    .uri(url)
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();

            if (response != null && response.containsKey("candidates")) {
                List<?> candidates = (List<?>) response.get("candidates");
                if (!candidates.isEmpty()) {
                    Map<?, ?> candidate = (Map<?, ?>) candidates.get(0);
                    Map<?, ?> content = (Map<?, ?>) candidate.get("content");
                    List<?> parts = (List<?>) content.get("parts");
                    Map<?, ?> part = (Map<?, ?>) parts.get(0);
                    return (String) part.get("text");
                }
            }
        } catch (Exception e) {
            log.error("Gemini API call failed", e);
        }

        return generateMockAdvice(totalRooms, emptyRooms, occupancyRate, netProfit);
    }

    private String generateMockAdvice(long totalRooms, long emptyRooms, double occupancyRate, double netProfit) {
        StringBuilder advice = new StringBuilder();
        advice.append("## 💡 Phân Tích Kinh Doanh\n\n");

        if (occupancyRate < 70) {
            advice.append("### ⚠️ Tỷ lệ lấp đầy thấp (").append(String.format("%.0f", occupancyRate)).append("%)\n");
            advice.append("Bạn đang có **").append(emptyRooms).append(" phòng trống**. Đây là điểm cần ưu tiên cải thiện.\n\n");
            advice.append("**Hành động đề xuất:**\n");
            advice.append("1. 📢 **Đẩy mạnh marketing**: Đăng tin lên Zalo, Facebook, các sàn cho thuê (Chợ Tốt, Batdongsan.com.vn)\n");
            advice.append("2. 💰 **Điều chỉnh giá**: Cân nhắc giảm giá thuê 5-10% trong 1-2 tháng đầu để thu hút khách\n");
            advice.append("3. 🎁 **Ưu đãi hấp dẫn**: Tặng 1 tháng phí điện/nước hoặc miễn tiền cọc để tăng cạnh tranh\n");
        } else if (occupancyRate >= 90) {
            advice.append("### ✅ Tỷ lệ lấp đầy rất tốt (").append(String.format("%.0f", occupancyRate)).append("%)\n\n");
            advice.append("**Hành động đề xuất:**\n");
            advice.append("1. 📈 **Tăng giá nhẹ**: Với tỷ lệ lấp đầy cao, bạn có thể tăng giá 5% khi gia hạn hợp đồng mới\n");
            advice.append("2. 🏗️ **Mở rộng quy mô**: Xem xét đầu tư thêm phòng hoặc dãy trọ mới để tăng doanh thu\n");
            advice.append("3. ⭐ **Nâng cấp tiện ích**: Đầu tư thêm wifi tốc độ cao, máy lạnh để giữ chân khách lâu dài\n");
        } else {
            advice.append("### 📊 Tỷ lệ lấp đầy ổn định (").append(String.format("%.0f", occupancyRate)).append("%)\n\n");
            advice.append("**Hành động đề xuất:**\n");
            advice.append("1. 🔧 **Duy trì chất lượng**: Bảo trì phòng ốc định kỳ để giữ khách cũ, giảm tỷ lệ rời bỏ\n");
            advice.append("2. 💡 **Tối ưu chi phí**: Rà soát lại các khoản chi phí vận hành, tìm nhà cung cấp dịch vụ giá cạnh tranh hơn\n");
            advice.append("3. 📋 **Quản lý hóa đơn đúng hạn**: Đảm bảo thu tiền thuê đúng ngày để tối ưu dòng tiền\n");
        }

        if (netProfit < 0) {
            advice.append("\n### 🔴 Lưu ý: Lợi nhuận âm\n");
            advice.append("Chi phí đang vượt doanh thu. Hãy xem xét cắt giảm các khoản chi không thiết yếu.\n");
        }

        return advice.toString();
    }
}
