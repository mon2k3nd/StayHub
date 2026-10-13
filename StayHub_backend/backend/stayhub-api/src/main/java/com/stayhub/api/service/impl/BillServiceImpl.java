package com.stayhub.api.service.impl;

import com.stayhub.api.entity.Bill;
import com.stayhub.api.entity.Contract;
import com.stayhub.api.entity.ContractStatus;
import com.stayhub.api.entity.Room;
import com.stayhub.api.entity.RoomStatus;
import com.stayhub.api.dto.response.RoomMeterReadingDto;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.entity.Vehicle;
import com.stayhub.api.repository.BillRepository;
import com.stayhub.api.repository.ContractRepository;
import com.stayhub.api.repository.VehicleRepository;
import com.stayhub.api.service.BillService;
import com.stayhub.api.service.ServicePoolService;
import com.stayhub.api.entity.ContractVoucher;
import com.stayhub.api.entity.SystemDebt;
import com.stayhub.api.entity.Voucher;
import com.stayhub.api.service.NotificationService;
import com.stayhub.api.service.AuditLogService;
import com.stayhub.api.repository.ContractVoucherRepository;
import com.stayhub.api.repository.SystemDebtRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import org.springframework.scheduling.annotation.Scheduled;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class BillServiceImpl implements BillService {

    private final BillRepository billRepository;
    private final ContractRepository contractRepository;
    private final com.stayhub.api.repository.UserRepository userRepository;
    private final com.stayhub.api.repository.RoomRepository roomRepository;
    private final com.stayhub.api.repository.TenantAddonRequestRepository tenantAddonRequestRepository;
    private final VehicleRepository vehicleRepository;
    private final com.stayhub.api.repository.RoommateRepository roommateRepository;
    private final com.stayhub.api.repository.DirectMessageRepository directMessageRepository;
    private final NotificationService notificationService;
    private final ContractVoucherRepository contractVoucherRepository;
    private final SystemDebtRepository systemDebtRepository;
    private final ServicePoolService servicePoolService;
    private final AuditLogService auditLogService;
    private final com.stayhub.api.service.WebSocketSessionManager webSocketSessionManager;
    private final ObjectMapper objectMapper;

    private static final double DEFAULT_ELECTRIC_PRICE = 3_500.0;
    private static final double DEFAULT_WATER_PRICE    = 15_000.0;

    @Override
    public List<Bill> getByTenant(Long tenantId) {
        return billRepository.findByTenantIdOrderByCreatedAtDesc(tenantId);
    }

    @Override
    public List<Bill> getUnpaidByTenant(Long tenantId) {
        return billRepository.findUnpaidByTenant(tenantId);
    }

    @Override
    public List<Bill> getByRoom(Long roomId) {
        return billRepository.findByRoomId(roomId);
    }

    @Override
    public List<Bill> getByOwner(Long ownerId) {
        return billRepository.findByOwnerId(ownerId);
    }

    @Override
    public List<Bill> getByStaff(Long staffId) {
        return billRepository.findByStaffId(staffId);
    }

    @Override
    @Transactional
    public Bill createBill(Bill bill) {
        Room room = null;
        Contract contract = null;
        if (bill.getContractId() != null) {
            contract = contractRepository.findById(bill.getContractId()).orElse(null);
            if (contract != null) {
                applyContractPrices(bill, contract);
                room = roomRepository.findById(contract.getRoomId()).orElse(null);
            }
        } else if (bill.getRoomId() != null) {
            contract = contractRepository.findByRoomIdAndStatusIn(bill.getRoomId(), List.of(ContractStatus.ACTIVE)).orElse(null);
            if (contract != null) {
                applyContractPrices(bill, contract);
            }
            room = roomRepository.findById(bill.getRoomId()).orElse(null);
        }
        
        com.stayhub.api.entity.PricingType waterType = com.stayhub.api.entity.PricingType.PER_INDEX;
        com.stayhub.api.entity.PricingType elecType = com.stayhub.api.entity.PricingType.PER_INDEX;
        if (room != null) {
            if (room.getWaterPricingType() != null) waterType = room.getWaterPricingType();
            if (room.getElectricityPricingType() != null) elecType = room.getElectricityPricingType();
        }

        // Tính tiền điện
        double electricPrice = bill.getElectricUnitPrice() != null ? bill.getElectricUnitPrice() : DEFAULT_ELECTRIC_PRICE;
        if (elecType == com.stayhub.api.entity.PricingType.PER_ROOM) {
            bill.setElectricAmount(electricPrice);
        } else if (elecType == com.stayhub.api.entity.PricingType.PER_PERSON) {
            int tenantCount = 1;
            if (contract != null) {
                tenantCount += roommateRepository.countByContractIdAndIsActiveTrue(contract.getId());
            }
            bill.setElectricAmount(electricPrice * tenantCount);
        } else {
            // PER_INDEX
            if (bill.getElectricCurrent() != null && bill.getElectricPrevious() != null) {
                double usage = 0;
                if (Boolean.TRUE.equals(bill.getIsElectricMeterReset()) && bill.getOldElectricMeterFinalReading() != null) {
                    if (bill.getOldElectricMeterFinalReading() < bill.getElectricPrevious()) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Số chốt đồng hồ cũ điện không hợp lệ");
                    }
                    usage = (bill.getOldElectricMeterFinalReading() - bill.getElectricPrevious()) + bill.getElectricCurrent();
                } else {
                    if (bill.getElectricCurrent() < bill.getElectricPrevious()) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ số điện cuối kỳ không được nhỏ hơn đầu kỳ");
                    }
                    usage = bill.getElectricCurrent() - bill.getElectricPrevious();
                }
                bill.setElectricAmount(usage * electricPrice);
            }
        }

        // Tính tiền nước
        double waterPrice = bill.getWaterUnitPrice() != null ? bill.getWaterUnitPrice() : DEFAULT_WATER_PRICE;
        if (waterType == com.stayhub.api.entity.PricingType.PER_ROOM) {
            bill.setWaterAmount(waterPrice);
        } else if (waterType == com.stayhub.api.entity.PricingType.PER_PERSON) {
            int tenantCount = 1;
            if (contract != null) {
                tenantCount += roommateRepository.countByContractIdAndIsActiveTrue(contract.getId());
            }
            bill.setWaterAmount(waterPrice * tenantCount);
        } else {
            // PER_INDEX
            if (bill.getWaterCurrent() != null && bill.getWaterPrevious() != null) {
                double usage = 0;
                if (Boolean.TRUE.equals(bill.getIsWaterMeterReset()) && bill.getOldWaterMeterFinalReading() != null) {
                    if (bill.getOldWaterMeterFinalReading() < bill.getWaterPrevious()) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Số chốt đồng hồ cũ nước không hợp lệ");
                    }
                    usage = (bill.getOldWaterMeterFinalReading() - bill.getWaterPrevious()) + bill.getWaterCurrent();
                } else {
                    if (bill.getWaterCurrent() < bill.getWaterPrevious()) {
                        throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ số nước cuối kỳ không được nhỏ hơn đầu kỳ");
                    }
                    usage = bill.getWaterCurrent() - bill.getWaterPrevious();
                }
                bill.setWaterAmount(usage * waterPrice);
            }
        }

        // Tích hợp chi phí Dịch vụ cộng thêm (Add-on Services)
        if (bill.getRoomId() != null) {
            List<com.stayhub.api.entity.TenantAddonRequest> addonRequests = 
                    tenantAddonRequestRepository.findByRoomIdAndIsBilledFalseAndStatus(bill.getRoomId(), "APPROVED");
            
            double addonTotal = 0;
            List<Long> billedRequestIds = new java.util.ArrayList<>();
            for (com.stayhub.api.entity.TenantAddonRequest req : addonRequests) {
                if (req.getBillMonth() != null && req.getBillYear() != null &&
                    req.getBillMonth().equals(bill.getMonth()) && req.getBillYear().equals(bill.getYear())) {
                    
                    addonTotal += req.getQuantity() * req.getAddonService().getPrice();
                    billedRequestIds.add(req.getId());
                }
            }

            if (!billedRequestIds.isEmpty()) {
                tenantAddonRequestRepository.markAsBilled(billedRequestIds);
            }

            List<Vehicle> vehicles = vehicleRepository.findByRoomId(bill.getRoomId());
            for (Vehicle v : vehicles) {
                if ("APPROVED".equals(v.getStatus()) && v.getMonthlyFee() != null) {
                    addonTotal += v.getMonthlyFee();
                }
            }

            if (addonTotal > 0) {
                double currentServiceAmount = bill.getServiceAmount() != null ? bill.getServiceAmount() : 0.0;
                bill.setServiceAmount(currentServiceAmount + addonTotal);
                log.info("Đã cộng {} VNĐ tiền dịch vụ (bao gồm xe) vào hóa đơn", addonTotal);
            }
        }

        // === SERVICE POOL ENGINE: Tính phí dịch vụ dùng chung (Nhóm Điện/Nước Chung Tầng/Tòa) ===
        if (bill.getRoomId() != null) {
            try {
                List<java.util.Map<String, Object>> poolShares =
                        servicePoolService.calculateAllSharedServicesForRoom(bill.getRoomId());
                if (!poolShares.isEmpty()) {
                    double poolTotal = poolShares.stream()
                            .mapToDouble(p -> (double) p.get("myShare"))
                            .sum();
                    double currentService = bill.getServiceAmount() != null ? bill.getServiceAmount() : 0.0;
                    bill.setServiceAmount(currentService + poolTotal);
                    bill.setSharedPoolAmount(poolTotal);
                    // Lưu chi tiết vào serviceDetails (JSON array)
                    bill.setServiceDetails(objectMapper.writeValueAsString(poolShares));
                    log.info("[ServicePool] Phòng {} - Tổng phí Pool: {} VNĐ. Chi tiết: {}",
                            bill.getRoomId(), poolTotal, poolShares);
                }
            } catch (Exception e) {
                log.warn("[ServicePool] Không thể tính phí Pool cho phòng {}: {}", bill.getRoomId(), e.getMessage());
            }
        }

        // Tính tổng
        double total = 0;
        
        double rent = bill.getRentAmount() != null ? bill.getRentAmount() : 0.0;
        double service = bill.getServiceAmount() != null ? bill.getServiceAmount() : 0.0;

        if (Boolean.TRUE.equals(bill.getIsProrated()) && bill.getProratedDays() != null) {
            double ratio = bill.getProratedDays() / 30.0;
            rent = rent * ratio;
            service = service * ratio;
            bill.setRentAmount(rent);
            bill.setServiceAmount(service);
        }

        total += rent;
        if (bill.getElectricAmount() != null) total += bill.getElectricAmount();
        if (bill.getWaterAmount()   != null) total += bill.getWaterAmount();
        total += service;

        // --- BẮT ĐẦU VOUCHER ENGINE & SETTLEMENT ---
        double discountAmount = 0;
        if (bill.getContractId() != null) {
            ContractVoucher activeVoucher = contractVoucherRepository.findByContractIdAndStatus(
                    bill.getContractId(), ContractVoucher.ContractVoucherStatus.ACTIVE).orElse(null);

            if (activeVoucher != null) {
                // Tính toán tiền giảm giá
                double basePrice = 0;
                switch (activeVoucher.getSnapshotAppliesTo()) {
                    case RENT_ONLY:
                        basePrice = rent;
                        break;
                    case SERVICE_ONLY:
                        basePrice = service;
                        break;
                    case TOTAL_BILL:
                        basePrice = total;
                        break;
                }

                if (activeVoucher.getSnapshotDiscountType() == Voucher.DiscountType.FIXED_AMOUNT) {
                    discountAmount = Math.min(activeVoucher.getSnapshotDiscountAmount(), basePrice);
                } else {
                    double percentDiscount = basePrice * (activeVoucher.getSnapshotDiscountPercent() / 100.0);
                    if (activeVoucher.getSnapshotMaxDiscount() != null) {
                        percentDiscount = Math.min(percentDiscount, activeVoucher.getSnapshotMaxDiscount());
                    }
                    discountAmount = percentDiscount;
                }

                // Cập nhật Tracking
                activeVoucher.setAppliedMonthsCount(activeVoucher.getAppliedMonthsCount() + 1);
                if (activeVoucher.getAppliedMonthsCount() >= activeVoucher.getSnapshotMonthsPerTenant()) {
                    activeVoucher.setStatus(ContractVoucher.ContractVoucherStatus.COMPLETED);
                }
                contractVoucherRepository.save(activeVoucher);

                // Settlement Engine: Nếu Sàn (ADMIN) tài trợ -> Sinh bản ghi Công nợ để trả cho Chủ nhà
                if (activeVoucher.getSnapshotFundedBy() == Voucher.FundedBy.ADMIN && discountAmount > 0) {
                    Long ownerId = contractRepository.findById(bill.getContractId()).map(com.stayhub.api.entity.Contract::getOwnerId).orElse(0L);
                    SystemDebt debt = SystemDebt.builder()
                            .landlordId(ownerId)
                            .contractId(bill.getContractId())
                            .voucherId(activeVoucher.getVoucherId())
                            .debtAmount(discountAmount)
                            .build();
                    // Will set billId after bill is saved
                    bill.setDiscountAmount(discountAmount); // Tạm lưu qua field nào đó nếu bill có field này
                }
            }
        }
        
        total = Math.max(0, total - discountAmount);
        bill.setTotalAmount(total);

        if (total == 0) {
            bill.setStatus("PAID");
            bill.setIsPaid(true);
            bill.setPaidAt(LocalDateTime.now());
        } else {
            bill.setStatus("PENDING");
            bill.setIsPaid(false);
        }

        bill.setCreatedAt(LocalDateTime.now());
        
        updateVietQr(bill);

        Bill saved = billRepository.save(bill);
        
        // Cập nhật lại billId cho SystemDebt nếu có
        if (discountAmount > 0 && bill.getContractId() != null) {
            ContractVoucher activeVoucher = contractVoucherRepository.findByContractId(bill.getContractId()).stream()
                .filter(v -> v.getSnapshotFundedBy() == Voucher.FundedBy.ADMIN)
                .findFirst().orElse(null);
            
            if (activeVoucher != null) {
                Long ownerId = contractRepository.findById(bill.getContractId()).map(com.stayhub.api.entity.Contract::getOwnerId).orElse(0L);
                SystemDebt debt = SystemDebt.builder()
                        .landlordId(ownerId)
                        .contractId(bill.getContractId())
                        .voucherId(activeVoucher.getVoucherId())
                        .billId(saved.getId())
                        .debtAmount(discountAmount)
                        .build();
                systemDebtRepository.save(debt);
            }
        }
        log.info("Tạo hóa đơn: id={}, room={}, total={}", saved.getId(), saved.getRoomId(), total);
        
        try {
            Long ownerId = 0L;
            if (bill.getContractId() != null) {
                ownerId = contractRepository.findById(bill.getContractId()).map(Contract::getOwnerId).orElse(0L);
            }
            
            String meta = String.format("{\"billId\":%d, \"amount\":%.0f, \"month\":%d, \"year\":%d}", 
                saved.getId(), saved.getTotalAmount(), saved.getMonth(), saved.getYear());
                
            com.stayhub.api.entity.DirectMessage msg = com.stayhub.api.entity.DirectMessage.builder()
                .roomId(saved.getRoomId())
                .senderId(ownerId)
                .senderName("Hệ Thống StayHub")
                .content("Hóa đơn tháng " + saved.getMonth() + "/" + saved.getYear() + " đã được tạo.")
                .messageType("BILL_CARD")
                .metadata(meta)
                .createdAt(LocalDateTime.now())
                .build();
            directMessageRepository.save(msg);
        } catch(Exception e) {
            log.error("Lỗi khi tạo tin nhắn thẻ hóa đơn", e);
        }

        auditLogService.logAction(
                "BILL", 
                saved.getId(), 
                "CREATE", 
                null, 
                "System", 
                "Hóa đơn tháng " + saved.getMonth() + "/" + saved.getYear() + " được tạo."
        );

        if (saved.getTenantId() != null) {
            webSocketSessionManager.sendEvent(saved.getTenantId(), "{\"event\": \"bill_generated\", \"billId\": " + saved.getId() + "}");
        }

        return saved;
    }

    @Override
    @Transactional
    public Bill payCash(Long billId, Long staffId) {
        Bill bill = billRepository.findByIdWithLock(billId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hóa đơn ID: " + billId));

        if (Boolean.TRUE.equals(bill.getIsPaid())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Hóa đơn này đã được thanh toán");
        }

        if (staffId == null) {
            // Tenant requested to pay by cash, pending owner confirmation
            bill.setStatus("PENDING_CASH");
            log.info("Khách yêu cầu thanh toán tiền mặt: billId={}", billId);
        } else {
            // Owner/Staff directly marked as paid by cash
            bill.setIsPaid(true);
            bill.setPaidAt(LocalDateTime.now());
            bill.setPaidByCash(true);
            bill.setStatus("PAID");
            bill.setCollectedByStaffId(staffId);
            log.info("Thanh toán tiền mặt trực tiếp: billId={}, staffId={}", billId, staffId);
            
            auditLogService.logAction(
                    "BILL", 
                    bill.getId(), 
                    "UPDATE", 
                    staffId, 
                    "Staff", 
                    "Xác nhận đã thu tiền mặt."
            );
        }

        Bill saved = billRepository.save(bill);
        
        if (Boolean.TRUE.equals(bill.getIsPaid()) && bill.getRoomId() != null) {
            checkAndFreeRoomIfNoUnpaidBills(bill.getRoomId());
            if (bill.getTenantId() != null) {
                webSocketSessionManager.sendEvent(bill.getTenantId(), "{\"event\": \"bill_paid\", \"billId\": " + billId + "}");
                try {
                    notificationService.send(
                            staffId,
                            bill.getTenantId(),
                            com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                            "Thanh toán thành công",
                            "Nhân viên/Chủ nhà đã thu tiền mặt cho hóa đơn của bạn.",
                            com.stayhub.api.entity.NotificationType.GENERAL,
                            billId,
                            false,
                            null,
                            null
                    );
                } catch (Exception e) {
                    log.warn("Failed to send payment success notification: {}", e.getMessage());
                }
            }
        } else if ("PENDING_CASH".equals(bill.getStatus())) {
            // Notify owner that tenant requested cash payment
            if (bill.getContractId() != null) {
                contractRepository.findById(bill.getContractId()).ifPresent(c -> {
                    webSocketSessionManager.sendEvent(c.getOwnerId(), "{\"event\": \"bill_pending_cash\", \"billId\": " + billId + "}");
                    try {
                        notificationService.send(
                                bill.getTenantId(),
                                c.getOwnerId(),
                                com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                                "Yêu cầu thanh toán tiền mặt",
                                "Khách thuê đã yêu cầu thanh toán tiền mặt cho hóa đơn ID " + billId + ". Vui lòng kiểm tra và xác nhận.",
                                com.stayhub.api.entity.NotificationType.GENERAL,
                                billId,
                                false,
                                null,
                                null
                        );
                    } catch (Exception e) {
                        log.warn("Failed to send pending cash notification: {}", e.getMessage());
                    }
                });
            }
        }

        return saved;
    }

    @Override
    @Transactional
    public Bill confirmCashPayment(Long billId, Long ownerId) {
        Bill bill = billRepository.findByIdWithLock(billId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hóa đơn ID: " + billId));

        if (Boolean.TRUE.equals(bill.getIsPaid())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Hóa đơn này đã được thanh toán");
        }

        bill.setIsPaid(true);
        bill.setPaidAt(LocalDateTime.now());
        bill.setPaidByCash(true);
        bill.setStatus("PAID");
        if (ownerId != null) {
            bill.setCollectedByStaffId(ownerId);
        }

        log.info("Chủ nhà xác nhận nhận tiền mặt: billId={}, ownerId={}", billId, ownerId);
        auditLogService.logAction(
                "BILL", 
                bill.getId(), 
                "UPDATE", 
                ownerId, 
                "Owner", 
                "Xác nhận đã thu tiền mặt."
        );
        Bill saved = billRepository.save(bill);
        
        if (bill.getRoomId() != null) {
            checkAndFreeRoomIfNoUnpaidBills(bill.getRoomId());
        }
        
        if (bill.getTenantId() != null) {
            webSocketSessionManager.sendEvent(bill.getTenantId(), "{\"event\": \"bill_paid\", \"billId\": " + billId + "}");
            try {
                notificationService.send(
                        ownerId,
                        bill.getTenantId(),
                        com.stayhub.api.entity.NotificationScope.INDIVIDUAL,
                        "Thanh toán thành công",
                        "Chủ nhà đã xác nhận nhận tiền mặt cho hóa đơn của bạn.",
                        com.stayhub.api.entity.NotificationType.GENERAL,
                        billId,
                        false,
                        null,
                        null
                );
            } catch (Exception e) {
                log.warn("Failed to send payment success notification: {}", e.getMessage());
            }
        }

        return saved;
    }

    @Override
    public void checkAndFreeRoomIfNoUnpaidBills(Long roomId) {
        Room room = roomRepository.findByIdWithPessimisticLock(roomId).orElse(null);
        if (room != null && room.getStatus() == RoomStatus.CLEANING_TURNOVER) {
            boolean hasUnpaidBills = billRepository.existsByRoomIdAndStatusNot(roomId, "PAID");
            if (!hasUnpaidBills) {
                room.setStatus(RoomStatus.TRONG);
                room.setCurrentTenantId(null);
                roomRepository.save(room);

                // Expire active contracts for this room
                contractRepository.findByRoomId(roomId).forEach(contract -> {
                    if (contract.getStatus() == ContractStatus.ACTIVE) {
                        contract.setStatus(ContractStatus.EXPIRED);
                        contractRepository.save(contract);
                    }
                });
                
                log.info("Phòng {} đã được thanh toán sạch nợ. Chuyển về trạng thái TRONG và đóng hợp đồng.", roomId);
            }
        }
    }

    private void applyContractPrices(Bill bill, Contract contract) {
        if (bill.getElectricUnitPrice() == null && contract.getElectricityPrice() != null) {
            bill.setElectricUnitPrice(contract.getElectricityPrice());
        }
        if (bill.getWaterUnitPrice() == null && contract.getWaterPrice() != null) {
            bill.setWaterUnitPrice(contract.getWaterPrice());
        }
        if (bill.getRentAmount() == null && contract.getMonthlyRent() != null) {
            bill.setRentAmount(contract.getMonthlyRent());
        }
        if (bill.getServiceAmount() == null && contract.getServiceFee() != null) {
            bill.setServiceAmount(contract.getServiceFee());
        }
        if (bill.getTenantId() == null) {
            bill.setTenantId(contract.getTenantId());
        }
    }

    private void updateVietQr(Bill bill) {
        if (bill.getTotalAmount() == null || bill.getTotalAmount() <= 0) return;
        
        Long ownerId = null;
        if (bill.getContractId() != null) {
            ownerId = contractRepository.findById(bill.getContractId()).map(Contract::getOwnerId).orElse(null);
        } else if (bill.getRoomId() != null) {
            ownerId = contractRepository.findByRoomIdAndStatusIn(bill.getRoomId(), List.of(ContractStatus.ACTIVE))
                    .map(Contract::getOwnerId).orElse(null);
        }

        if (ownerId != null) {
            userRepository.findById(ownerId).ifPresent(owner -> {
                var profile = owner.getOwnerProfile();
                if (profile != null && profile.getBankName() != null && profile.getBankAccountNumber() != null) {
                    try {
                        String bankName = java.net.URLEncoder.encode(profile.getBankName(), "UTF-8");
                        String accNo = java.net.URLEncoder.encode(profile.getBankAccountNumber(), "UTF-8");
                        String amount = String.format("%.0f", bill.getTotalAmount());
                        String addInfo = java.net.URLEncoder.encode("Thanh toan tien phong " + bill.getRoomId() + " thang " + bill.getMonth(), "UTF-8");
                        String qrUrl = "https://img.vietqr.io/image/" + bankName + "-" + accNo + "-compact2.png?amount=" + amount + "&addInfo=" + addInfo;
                        if (profile.getBankAccountName() != null) {
                            qrUrl += "&accountName=" + java.net.URLEncoder.encode(profile.getBankAccountName(), "UTF-8");
                        }
                        bill.setPaymentQrUrl(qrUrl);
                    } catch (Exception e) {
                        log.error("Failed to generate VietQR url", e);
                    }
                }
            });
        }
    }

    @Override
    @Transactional
    public Bill updateUtilities(Long billId, Double electricCurrent, Double waterCurrent, String electricImage, String waterImage) {
        Bill bill = billRepository.findById(billId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hóa đơn ID: " + billId));

        if (Boolean.TRUE.equals(bill.getIsPaid())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Hóa đơn đã thanh toán, không thể sửa chỉ số");
        }

        if (electricCurrent != null) bill.setElectricCurrent(electricCurrent);
        if (waterCurrent != null) bill.setWaterCurrent(waterCurrent);
        if (electricImage != null) bill.setElectricImage(electricImage);
        if (waterImage != null) bill.setWaterImage(waterImage);

        // Lấy thông tin phòng để kiểm tra PricingType
        Room room = null;
        if (bill.getRoomId() != null) {
            room = roomRepository.findById(bill.getRoomId()).orElse(null);
        }
        com.stayhub.api.entity.PricingType waterType = com.stayhub.api.entity.PricingType.PER_INDEX;
        com.stayhub.api.entity.PricingType elecType = com.stayhub.api.entity.PricingType.PER_INDEX;
        if (room != null) {
            if (room.getWaterPricingType() != null) waterType = room.getWaterPricingType();
            if (room.getElectricityPricingType() != null) elecType = room.getElectricityPricingType();
        }

        // Tính lại tiền điện nếu tính theo chỉ số
        if (elecType == com.stayhub.api.entity.PricingType.PER_INDEX && bill.getElectricCurrent() != null && bill.getElectricPrevious() != null) {
            double usage = 0;
            if (Boolean.TRUE.equals(bill.getIsElectricMeterReset()) && bill.getOldElectricMeterFinalReading() != null) {
                if (bill.getOldElectricMeterFinalReading() < bill.getElectricPrevious()) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Số chốt đồng hồ điện cũ không hợp lệ");
                }
                usage = (bill.getOldElectricMeterFinalReading() - bill.getElectricPrevious()) + bill.getElectricCurrent();
            } else {
                if (bill.getElectricCurrent() < bill.getElectricPrevious()) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ số điện mới không được nhỏ hơn chỉ số cũ");
                }
                usage = bill.getElectricCurrent() - bill.getElectricPrevious();
            }
            double electricPrice = bill.getElectricUnitPrice() != null ? bill.getElectricUnitPrice() : DEFAULT_ELECTRIC_PRICE;
            bill.setElectricAmount(usage * electricPrice);
        }

        // Tính lại tiền nước nếu tính theo chỉ số
        if (waterType == com.stayhub.api.entity.PricingType.PER_INDEX && bill.getWaterCurrent() != null && bill.getWaterPrevious() != null) {
            double usage = 0;
            if (Boolean.TRUE.equals(bill.getIsWaterMeterReset()) && bill.getOldWaterMeterFinalReading() != null) {
                if (bill.getOldWaterMeterFinalReading() < bill.getWaterPrevious()) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Số chốt đồng hồ nước cũ không hợp lệ");
                }
                usage = (bill.getOldWaterMeterFinalReading() - bill.getWaterPrevious()) + bill.getWaterCurrent();
            } else {
                if (bill.getWaterCurrent() < bill.getWaterPrevious()) {
                    throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ số nước mới không được nhỏ hơn chỉ số cũ");
                }
                usage = bill.getWaterCurrent() - bill.getWaterPrevious();
            }
            double waterPrice = bill.getWaterUnitPrice() != null ? bill.getWaterUnitPrice() : DEFAULT_WATER_PRICE;
            bill.setWaterAmount(usage * waterPrice);
        }

        // Tính tổng
        double total = 0;
        if (bill.getRentAmount()    != null) total += bill.getRentAmount();
        if (bill.getElectricAmount() != null) total += bill.getElectricAmount();
        if (bill.getWaterAmount()   != null) total += bill.getWaterAmount();
        if (bill.getServiceAmount() != null) total += bill.getServiceAmount();
        bill.setTotalAmount(total);

        updateVietQr(bill);

        log.info("Cập nhật điện nước cho Bill {}: Elec={}, Water={}, Total={}", billId, electricCurrent, waterCurrent, total);
        
        Bill updated = billRepository.save(bill);
        auditLogService.logAction(
                "BILL", 
                updated.getId(), 
                "UPDATE", 
                null, 
                "System", 
                "Cập nhật số điện/nước. Điện mới: " + electricCurrent + ", Nước mới: " + waterCurrent
        );
        
        return updated;
    }

    @Override
    public List<RoomMeterReadingDto> getMeterReadingsByBranch(Long branchId, int month, int year) {
        List<Room> rooms = roomRepository.findByBranchId(branchId);
        int previousMonth = month == 1 ? 12 : month - 1;
        int previousYear = month == 1 ? year - 1 : year;

        return rooms.stream()
                .filter(r -> r.getStatus() == RoomStatus.DA_THUE)
                .map(room -> {
                    // Find previous bill for previous indices
                    Bill previousBill = billRepository.findByRoomId(room.getId()).stream()
                            .filter(b -> b.getMonth() == previousMonth && b.getYear() == previousYear)
                            .findFirst()
                            .orElse(null);

                    // Find current bill if it exists
                    Bill currentBill = billRepository.findByRoomId(room.getId()).stream()
                            .filter(b -> b.getMonth() == month && b.getYear() == year)
                            .findFirst()
                            .orElse(null);

                    Double elecPrev = previousBill != null && previousBill.getElectricCurrent() != null 
                            ? previousBill.getElectricCurrent() : 0.0;
                    Double waterPrev = previousBill != null && previousBill.getWaterCurrent() != null 
                            ? previousBill.getWaterCurrent() : 0.0;

                    return RoomMeterReadingDto.builder()
                            .roomId(room.getId())
                            .roomName(room.getRoomName())
                            .currentTenantId(room.getCurrentTenantId())
                            .currentContractId(room.getCurrentContractId())
                            .electricPrevious(elecPrev)
                            .waterPrevious(waterPrev)
                            .electricCurrent(currentBill != null ? currentBill.getElectricCurrent() : null)
                            .waterCurrent(currentBill != null ? currentBill.getWaterCurrent() : null)
                            .currentMonthBillId(currentBill != null ? currentBill.getId() : null)
                            .month(month)
                            .year(year)
                            .build();
                })
                .toList();
    }

    @Override
    @Transactional
    public List<Bill> generateBillsForBranch(Long branchId, int month, int year) {
        List<Room> rooms = roomRepository.findByBranchId(branchId);
        int previousMonth = month == 1 ? 12 : month - 1;
        int previousYear = month == 1 ? year - 1 : year;
        
        List<Bill> generatedBills = new java.util.ArrayList<>();

        for (Room room : rooms) {
            if (room.getStatus() != RoomStatus.DA_THUE) continue;

            // Check if bill already exists for this month
            boolean exists = billRepository.findByRoomId(room.getId()).stream()
                    .anyMatch(b -> b.getMonth() == month && b.getYear() == year);
            if (exists) continue;

            // Find previous bill
            Bill previousBill = billRepository.findByRoomId(room.getId()).stream()
                    .filter(b -> b.getMonth() == previousMonth && b.getYear() == previousYear)
                    .findFirst()
                    .orElse(null);

            Double elecPrev = previousBill != null && previousBill.getElectricCurrent() != null 
                    ? previousBill.getElectricCurrent() : 0.0;
            Double waterPrev = previousBill != null && previousBill.getWaterCurrent() != null 
                    ? previousBill.getWaterCurrent() : 0.0;

            Bill newBill = Bill.builder()
                    .roomId(room.getId())
                    .contractId(room.getCurrentContractId())
                    .tenantId(room.getCurrentTenantId())
                    // ownerId is implicitly retrieved from contract in createBill if not set, but wait! Bill doesn't have ownerId field!
                    // Wait, does Bill have ownerId? I didn't see ownerId in Bill.java. It is added? No!
                    .month(month)
                    .year(year)
                    .electricPrevious(elecPrev)
                    .waterPrevious(waterPrev)
                    .build();

            generatedBills.add(createBill(newBill));
        }

        return generatedBills;
    }

    @Override
    @Transactional
    public Bill generateBillForRoom(Long roomId, int month, int year) {
        Room room = roomRepository.findById(roomId).orElseThrow(() -> new ResourceNotFoundException("Phòng không tồn tại"));
        if (room.getStatus() != RoomStatus.DA_THUE) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Phòng chưa được thuê, không thể tạo hóa đơn");
        }

        // Check if bill already exists for this month
        Bill existingBill = billRepository.findByRoomId(roomId).stream()
                .filter(b -> b.getMonth() == month && b.getYear() == year)
                .findFirst()
                .orElse(null);
        if (existingBill != null) return existingBill;

        int previousMonth = month == 1 ? 12 : month - 1;
        int previousYear = month == 1 ? year - 1 : year;

        // Find previous bill
        Bill previousBill = billRepository.findByRoomId(roomId).stream()
                .filter(b -> b.getMonth() == previousMonth && b.getYear() == previousYear)
                .findFirst()
                .orElse(null);

        Double elecPrev = previousBill != null && previousBill.getElectricCurrent() != null 
                ? previousBill.getElectricCurrent() : 0.0;
        Double waterPrev = previousBill != null && previousBill.getWaterCurrent() != null 
                ? previousBill.getWaterCurrent() : 0.0;

        Bill newBill = Bill.builder()
                .roomId(room.getId())
                .contractId(room.getCurrentContractId())
                .tenantId(room.getCurrentTenantId())
                .month(month)
                .year(year)
                .electricPrevious(elecPrev)
                .waterPrevious(waterPrev)
                .build();

        return createBill(newBill);
    }

    @Override
    @Transactional
    public Bill createInitialBill(com.stayhub.api.entity.Contract contract) {
        Room room = roomRepository.findById(contract.getRoomId())
                .orElseThrow(() -> new ResourceNotFoundException("Phòng không tồn tại"));

        double rentAmount = room.getPrice() != null ? room.getPrice() : 0.0;
        double depositAmount = contract.getDepositAmount() != null ? contract.getDepositAmount() : 0.0;
        double totalAmount = rentAmount + depositAmount;

        Bill initialBill = Bill.builder()
                .roomId(room.getId())
                .contractId(contract.getId())
                .tenantId(contract.getTenantId())
                .month(LocalDateTime.now().getMonthValue())
                .year(LocalDateTime.now().getYear())
                .type("INITIAL_PAYMENT")
                .status("PENDING")
                .rentAmount(rentAmount)
                .serviceAmount(depositAmount) // Tạm lưu tiền cọc vào serviceAmount hoặc một trường khác nếu chưa có depositAmount riêng trong Bill. Tuy nhiên Bill chưa có trường depositAmount, nên lưu vào serviceAmount và ghi log hoặc tốt nhất là tự cộng vào tổng. Để minh bạch, tạm lưu serviceAmount = depositAmount.
                .totalAmount(totalAmount)
                .dueDate(LocalDateTime.now().plusHours(24))
                .isPaid(false)
                .createdAt(LocalDateTime.now())
                .build();

        updateVietQr(initialBill);
        Bill saved = billRepository.save(initialBill);
        log.info("Tạo hóa đơn Khởi tạo thành công: billId={}, total={}, dueDate={}", saved.getId(), totalAmount, saved.getDueDate());
        return saved;
    }

    @Scheduled(cron = "0 */5 * * * *") // Run every 5 minutes
    @Transactional
    public void scanAndCancelExpiredInitialBills() {
        LocalDateTime now = LocalDateTime.now();
        List<Bill> expiredBills = billRepository.findAll().stream()
                .filter(b -> "INITIAL_PAYMENT".equals(b.getType()))
                .filter(b -> "PENDING".equals(b.getStatus()))
                .filter(b -> b.getDueDate() != null && b.getDueDate().isBefore(now))
                .toList();

        for (Bill bill : expiredBills) {
            bill.setStatus("EXPIRED");
            billRepository.save(bill);

            contractRepository.findById(bill.getContractId()).ifPresent(contract -> {
                contract.setStatus(ContractStatus.VOID_BY_TIMEOUT);
                contractRepository.save(contract);
            });

            roomRepository.findById(bill.getRoomId()).ifPresent(room -> {
                room.setStatus(RoomStatus.TRONG);
                room.setCurrentTenantId(null);
                room.setCurrentContractId(null);
                roomRepository.save(room);
            });

            log.warn("Hóa đơn khởi tạo {} đã hết hạn 24h. Tự động hủy hợp đồng và giải phóng phòng.", bill.getId());
        }
    }
}
