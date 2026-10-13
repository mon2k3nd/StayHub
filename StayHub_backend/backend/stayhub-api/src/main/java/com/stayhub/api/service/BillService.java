package com.stayhub.api.service;

import com.stayhub.api.entity.Bill;
import java.util.List;

public interface BillService {
    List<Bill> getByTenant(Long tenantId);
    List<Bill> getUnpaidByTenant(Long tenantId);
    List<Bill> getByRoom(Long roomId);
    Bill createBill(Bill bill);
    Bill payCash(Long billId, Long staffId);
    Bill confirmCashPayment(Long billId, Long ownerId);
    List<Bill> getByOwner(Long ownerId);
    List<Bill> getByStaff(Long staffId);
    Bill updateUtilities(Long billId, Double electricCurrent, Double waterCurrent, String electricImage, String waterImage);
    List<com.stayhub.api.dto.response.RoomMeterReadingDto> getMeterReadingsByBranch(Long branchId, int month, int year);
    List<Bill> generateBillsForBranch(Long branchId, int month, int year);
    Bill generateBillForRoom(Long roomId, int month, int year);
    Bill createInitialBill(com.stayhub.api.entity.Contract contract);
    void checkAndFreeRoomIfNoUnpaidBills(Long roomId);
}
