package com.stayhub.api.service.impl;

import com.stayhub.api.entity.BranchMeter;
import com.stayhub.api.entity.Bill;
import com.stayhub.api.repository.BranchMeterRepository;
import com.stayhub.api.repository.BillRepository;
import com.stayhub.api.service.BranchMeterService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class BranchMeterServiceImpl implements BranchMeterService {

    private final BranchMeterRepository branchMeterRepository;
    private final BillRepository billRepository;

    @Override
    public BranchMeter saveMasterMeter(Long branchId, int month, int year, Double elec, Double water) {
        BranchMeter meter = branchMeterRepository.findByBranchIdAndMonthAndYear(branchId, month, year)
                .orElse(BranchMeter.builder().branchId(branchId).month(month).year(year).build());
        
        // Cập nhật số cũ nếu có tháng trước đó (giả lập đơn giản)
        if (meter.getId() == null) {
            int prevMonth = month == 1 ? 12 : month - 1;
            int prevYear = month == 1 ? year - 1 : year;
            branchMeterRepository.findByBranchIdAndMonthAndYear(branchId, prevMonth, prevYear)
                    .ifPresent(prev -> {
                        meter.setElectricMasterPrevious(prev.getElectricMasterCurrent());
                        meter.setWaterMasterPrevious(prev.getWaterMasterCurrent());
                    });
        }

        meter.setElectricMasterCurrent(elec);
        meter.setWaterMasterCurrent(water);
        meter.setUpdatedAt(LocalDateTime.now());
        return branchMeterRepository.save(meter);
    }

    @Override
    public BranchMeter getMasterMeter(Long branchId, int month, int year) {
        return branchMeterRepository.findByBranchIdAndMonthAndYear(branchId, month, year).orElse(null);
    }

    @Override
    public Map<String, Object> getUtilityLeakageReport(Long branchId, int month, int year) {
        Map<String, Object> result = new HashMap<>();
        
        // 1. Lấy chỉ số đồng hồ tổng
        BranchMeter master = getMasterMeter(branchId, month, year);
        double masterElecDiff = 0.0;
        double masterWaterDiff = 0.0;
        if (master != null) {
            masterElecDiff = (master.getElectricMasterCurrent() != null ? master.getElectricMasterCurrent() : 0.0) 
                           - (master.getElectricMasterPrevious() != null ? master.getElectricMasterPrevious() : 0.0);
            masterWaterDiff = (master.getWaterMasterCurrent() != null ? master.getWaterMasterCurrent() : 0.0) 
                            - (master.getWaterMasterPrevious() != null ? master.getWaterMasterPrevious() : 0.0);
        }

        // 2. Lấy tổng tiêu thụ các phòng từ hóa đơn
        List<Bill> bills = billRepository.findByBranchIdAndMonthAndYear(branchId, month, year); // Giả sử có method này, hoặc tự filter
        double roomsElecDiff = 0.0;
        double roomsWaterDiff = 0.0;

        for (Bill b : bills) {
            if (b.getElectricCurrent() != null && b.getElectricPrevious() != null) {
                roomsElecDiff += (b.getElectricCurrent() - b.getElectricPrevious());
            }
            if (b.getWaterCurrent() != null && b.getWaterPrevious() != null) {
                roomsWaterDiff += (b.getWaterCurrent() - b.getWaterPrevious());
            }
        }

        result.put("month", month);
        result.put("year", year);
        result.put("masterElectricUsage", masterElecDiff > 0 ? masterElecDiff : 0.0);
        result.put("roomsElectricUsage", roomsElecDiff);
        result.put("electricLeakage", (masterElecDiff > 0 ? masterElecDiff : 0.0) - roomsElecDiff);
        
        result.put("masterWaterUsage", masterWaterDiff > 0 ? masterWaterDiff : 0.0);
        result.put("roomsWaterUsage", roomsWaterDiff);
        result.put("waterLeakage", (masterWaterDiff > 0 ? masterWaterDiff : 0.0) - roomsWaterDiff);

        return result;
    }
}
