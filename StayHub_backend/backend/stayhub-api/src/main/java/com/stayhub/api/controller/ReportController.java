package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Contract;
import com.stayhub.api.entity.ContractStatus;
import com.stayhub.api.entity.Room;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.RoomRepository;
import com.stayhub.api.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.format.DateTimeFormatter;
import java.util.*;

@RestController
@RequestMapping("/v1/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ContractRepository contractRepository;
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;

    /**
     * Xuất danh sách tạm trú CT01 theo khu trọ
     * Trả về danh sách JSON để Flutter tự render PDF
     */
    @GetMapping("/ct01/{branchId}")
    public ResponseEntity<ApiResponse<Map<String, Object>>> exportCT01(@PathVariable Long branchId) {
        try {
            List<Room> rooms = roomRepository.findByBranchId(branchId);
            List<Map<String, Object>> tenantList = new ArrayList<>();

            DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy");

            for (Room room : rooms) {
                List<Contract> activeContracts = contractRepository
                        .findByRoomIdAndStatus(room.getId(), ContractStatus.ACTIVE);

                for (Contract contract : activeContracts) {
                    Optional<User> tenantOpt = userRepository.findById(contract.getTenantId());
                    if (tenantOpt.isEmpty()) continue;
                    User tenant = tenantOpt.get();

                    var tp = tenant.getTenantProfile();
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("roomName", room.getRoomName() != null ? room.getRoomName() : "Phòng " + room.getId());
                    row.put("tenantName", tenant.getName());
                    row.put("cccdNumber", tp != null && tp.getCccdNumber() != null ? tp.getCccdNumber() : "");
                    row.put("dateOfBirth", tp != null && tp.getDateOfBirth() != null
                            ? tp.getDateOfBirth().format(fmt) : "");
                    row.put("gender", tp != null && tp.getGender() != null ? tp.getGender() : "");
                    row.put("hometown", tp != null && tp.getHometown() != null ? tp.getHometown() : "");
                    row.put("occupation", tp != null && tp.getOccupation() != null ? tp.getOccupation() : "");
                    row.put("phoneNumber", tenant.getPhoneNumber());
                    row.put("checkInDate", contract.getStartDate() != null
                            ? contract.getStartDate().toString() : "");
                    row.put("cccdIssueDate", tp != null && tp.getCccdIssueDate() != null
                            ? tp.getCccdIssueDate().format(fmt) : "");
                    row.put("cccdIssuePlace", tp != null && tp.getCccdIssuePlace() != null
                            ? tp.getCccdIssuePlace() : "");
                    row.put("emergencyContactName", tp != null && tp.getEmergencyContactName() != null
                            ? tp.getEmergencyContactName() : "");
                    row.put("emergencyContactPhone", tp != null && tp.getEmergencyContactPhone() != null
                            ? tp.getEmergencyContactPhone() : "");
                    tenantList.add(row);
                }
            }

            Map<String, Object> result = new HashMap<>();
            result.put("branchId", branchId);
            result.put("exportDate", java.time.LocalDate.now().format(fmt));
            result.put("totalTenants", tenantList.size());
            result.put("tenants", tenantList);

            return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                    .success(true).message("Xuất danh sách tạm trú thành công!")
                    .data(result).build());

        } catch (Exception e) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.<Map<String, Object>>builder()
                            .success(false).message(e.getMessage()).build());
        }
    }
}
