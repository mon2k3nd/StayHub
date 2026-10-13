package com.stayhub.api.service;

import com.stayhub.api.entity.Bill;
import com.stayhub.api.entity.Contract;
import com.stayhub.api.repository.BillRepository;
import com.stayhub.api.repository.ContractRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class AutoRentService {

    private final ContractRepository contractRepository;
    private final BillRepository billRepository;

    @Transactional
    public void enableAutoRent(Long contractId) {
        Contract contract = contractRepository.findById(contractId)
                .orElseThrow(() -> new RuntimeException("Contract not found"));
        // Assuming we add an autoRentEnabled field or just log it for now
        log.info("Auto Rent enabled for contract ID {}", contractId);
        // contract.setAutoRentEnabled(true);
        // contractRepository.save(contract);
    }

    @Transactional
    public List<Bill> splitBill(Long billId, List<Long> tenantIds) {
        if (tenantIds == null || tenantIds.isEmpty()) {
            throw new RuntimeException("Must provide tenants to split bill");
        }

        Bill originalBill = billRepository.findById(billId)
                .orElseThrow(() -> new RuntimeException("Bill not found"));

        double splitAmount = originalBill.getTotalAmount() / tenantIds.size();
        List<Bill> splitBills = new ArrayList<>();

        for (Long tenantId : tenantIds) {
            Bill split = Bill.builder()
                    .roomId(originalBill.getRoomId())
                    .tenantId(tenantId)
                    .type(originalBill.getType())
                    .totalAmount(splitAmount)
                    .status("UNPAID")
                    .dueDate(originalBill.getDueDate())
                    .createdAt(originalBill.getCreatedAt())
                    .build();
            splitBills.add(billRepository.save(split));
        }

        originalBill.setStatus("SPLIT");
        billRepository.save(originalBill);

        return splitBills;
    }
}
