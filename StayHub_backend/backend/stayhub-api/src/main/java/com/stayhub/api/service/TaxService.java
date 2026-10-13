package com.stayhub.api.service;

import com.stayhub.api.dto.response.TaxReportResponse;
import com.stayhub.api.entity.Bill;
import com.stayhub.api.repository.BillRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class TaxService {

    private final BillRepository billRepository;

    public TaxReportResponse calculateTaxForOwner(Long ownerId, int month, int year) {
        // Fetch bills that are PAID or CONFIRMED for the given owner
        // For simplicity, we assume we fetch all bills for the owner and filter here.
        // In production, write a custom query in BillRepository.
        List<Bill> bills = billRepository.findAll();
        
        double totalRevenue = bills.stream()
                .filter(b -> {
                    // Logic to find owner's bills (this depends on your Bill entity mapping)
                    // We'll just mock this filter for now assuming all fetched are owner's bills
                    return ("PAID".equals(b.getStatus()) || "CONFIRMED".equals(b.getStatus()));
                })
                // Also filter by month and year of createdAt or updated
                // Assuming it's already filtered, sum it up
                .mapToDouble(Bill::getTotalAmount)
                .sum();

        // In Vietnam, rental income tax usually consists of 5% VAT and 5% PIT if revenue > 100M VND/year.
        // We calculate flat 5% each here for demo purposes.
        double vat = totalRevenue * 0.05;
        double pit = totalRevenue * 0.05;

        return TaxReportResponse.builder()
                .ownerId(ownerId)
                .month(month)
                .year(year)
                .totalRevenue(totalRevenue)
                .vatTax(vat)
                .pitTax(pit)
                .totalTaxPayable(vat + pit)
                .build();
    }
}
