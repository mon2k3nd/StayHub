package com.stayhub.api.service.impl;

import com.lowagie.text.Document;
import com.lowagie.text.Paragraph;
import com.lowagie.text.pdf.PdfWriter;
import com.stayhub.api.entity.ElectronicContract;
import com.stayhub.api.entity.User;
import com.stayhub.api.entity.Room;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.service.ContractAiService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;
import reactor.core.scheduler.Schedulers;

import com.stayhub.api.entity.OwnerContractTemplate;
import com.stayhub.api.repository.OwnerContractTemplateRepository;

import java.io.ByteArrayOutputStream;
import java.util.Map;
import java.util.UUID;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class ContractAiServiceImpl implements ContractAiService {

    private final UserRepository userRepository;
    private final RoomRepository roomRepository;
    private final OwnerContractTemplateRepository templateRepository;
    private final WebClient webClient = WebClient.builder().build();

    @Value("${gemini.api.key:mock_key}")
    private String geminiApiKey;

    @Override
    public Mono<String> generateAiAppendix(Long rentalRequestId, Long roomId, Long tenantId, Long ownerId) {
        return Mono.fromCallable(() -> {
            User tenant = userRepository.findById(tenantId).orElseThrow();
            Room room = roomRepository.findById(roomId).orElseThrow();
            
            Optional<OwnerContractTemplate> templateOpt = templateRepository.findById(ownerId);
            String ownerTerms = templateOpt.isPresent() && templateOpt.get().getTemplateText() != null && !templateOpt.get().getTemplateText().isBlank()
                    ? "Quy định riêng của Chủ nhà yêu cầu thêm vào hợp đồng: \n" + templateOpt.get().getTemplateText() + "\n"
                    : "bao gồm các quy định về giờ giấc, giữ gìn tài sản chung, và đền bù nếu vi phạm.";
            
            // Build Prompt
            String prompt = String.format(
                    "Hãy đóng vai là một luật sư soạn thảo hợp đồng cho thuê phòng trọ. " +
                    "Khách thuê là %s, nghề nghiệp: %s. Phòng thuê: %s, Giá thuê: %s VNĐ. " +
                    "Hãy sinh ra các điều khoản phụ lục ràng buộc pháp lý chặt chẽ (định dạng Markdown), " +
                    "%s",
                    tenant.getName(), 
                    tenant.getTenantProfile() != null && tenant.getTenantProfile().getOccupation() != null ? tenant.getTenantProfile().getOccupation() : "Tự do", 
                    room.getRoomName(), 
                    room.getPrice(),
                    ownerTerms
            );

            // Payload for Gemini API
            Map<String, Object> requestBody = Map.of(
                    "contents", new Object[]{
                            Map.of("parts", new Object[]{
                                    Map.of("text", prompt)
                            })
                    }
            );

            return requestBody;
        })
        .flatMap(requestBody -> {
            // Call Gemini API phi tuần tự (Non-blocking)
            String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=" + geminiApiKey;
            
            if ("mock_key".equals(geminiApiKey)) {
                // Mock response if no key is provided
                return Mono.just("- **Vệ sinh chung**: Khách thuê phải dọn dẹp vệ sinh khu vực sinh hoạt chung.\n- **Hư hỏng tài sản**: Bồi thường 100% giá trị tài sản nếu cố tình phá hoại.\n- **Giờ giấc**: Không làm ồn sau 22h00.");
            }

            return webClient.post()
                    .uri(url)
                    .header(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE)
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .map(response -> {
                        try {
                            Map<String, Object> candidate = (Map<String, Object>) ((java.util.List<?>) response.get("candidates")).get(0);
                            Map<String, Object> content = (Map<String, Object>) candidate.get("content");
                            Map<String, Object> part = (Map<String, Object>) ((java.util.List<?>) content.get("parts")).get(0);
                            return (String) part.get("text");
                        } catch (Exception e) {
                            log.error("Error parsing Gemini response", e);
                            return "- **Lỗi**: Không thể tạo phụ lục tự động do lỗi hệ thống AI.";
                        }
                    });
        });
    }

    @Override
    public Mono<String> generateAndUploadPdf(ElectronicContract contract) {
        // Tác vụ I/O nặng (sinh PDF và upload), phải chạy trên Schedulers.boundedElastic()
        return Mono.fromCallable(() -> {
            log.info("Generating PDF for Contract ID: {}", contract.getId());
            
            Document document = new Document();
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            PdfWriter.getInstance(document, out);

            document.open();
            
            // Add contract header
            document.add(new Paragraph("CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM\nĐộc lập - Tự do - Hạnh phúc\n\n"));
            document.add(new Paragraph("HỢP ĐỒNG CHO THUÊ PHÒNG TRỌ\n\n"));

            // Get users to populate info
            User tenant = userRepository.findById(contract.getTenantId()).orElse(null);
            User owner = userRepository.findById(contract.getOwnerId()).orElse(null);

            if (tenant != null) {
                var tp = tenant.getTenantProfile();
                document.add(new Paragraph("THÔNG TIN BÊN THUÊ (BÊN B):"));
                document.add(new Paragraph("Họ và tên: " + tenant.getName()));
                document.add(new Paragraph("Ngày sinh: " + (tp != null && tp.getDateOfBirth() != null ? tp.getDateOfBirth().toLocalDate().toString() : "")));
                document.add(new Paragraph("Số CCCD/CMND: " + (tp != null ? tp.getCccdNumber() : "")));
                document.add(new Paragraph("Ngày cấp: " + (tp != null && tp.getCccdIssueDate() != null ? tp.getCccdIssueDate().toLocalDate().toString() : "")));
                document.add(new Paragraph("Nơi cấp: " + (tp != null && tp.getCccdIssuePlace() != null ? tp.getCccdIssuePlace() : "")));
                document.add(new Paragraph("Số điện thoại: " + tenant.getPhoneNumber()));
                String mappedHometown = (tp != null && tp.getHometown() != null) ?
                        com.stayhub.api.service.AddressMapper.mapTo3Tier(tp.getHometown()).toFullAddress() : "";
                document.add(new Paragraph("Quê quán: " + mappedHometown));
                document.add(new Paragraph("Liên hệ khẩn cấp: " + (tp != null && tp.getEmergencyContactName() != null ? tp.getEmergencyContactName() : "") + " - " + (tp != null && tp.getEmergencyContactPhone() != null ? tp.getEmergencyContactPhone() : "")));
                document.add(new Paragraph("Phương tiện: " + (tp != null && tp.getVehicleType() != null ? tp.getVehicleType() : "") + " - BKS: " + (tp != null && tp.getLicensePlate() != null ? tp.getLicensePlate() : "")));
                document.add(new Paragraph("\n"));
            }
            
            // Add AI Appendix
            document.add(new Paragraph("ĐIỀU KHOẢN BỔ SUNG (BỞI STAYHUB AI):\n"));
            String appendix = contract.getAiAppendixClauses();
            if (appendix != null && !appendix.isEmpty()) {
                document.add(new Paragraph(appendix));
            }

            document.close();

            byte[] pdfBytes = out.toByteArray();
            log.info("PDF generated successfully. Size: {} bytes", pdfBytes.length);

            // Mock S3 Upload
            String s3Url = "https://s3.stayhub.com/contracts/contract_" + contract.getId() + "_" + UUID.randomUUID().toString() + ".pdf";
            return s3Url;
            
        }).subscribeOn(Schedulers.boundedElastic());
    }
}
