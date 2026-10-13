package com.stayhub.api.service.impl;

import com.stayhub.api.entity.Expense;
import com.stayhub.api.repository.BillRepository;
import com.stayhub.api.repository.ExpenseRepository;
import com.stayhub.api.service.ExpenseService;
import com.stayhub.api.service.AuditLogService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ExpenseServiceImpl implements ExpenseService {

    private final ExpenseRepository expenseRepository;
    private final BillRepository billRepository;
    private final AuditLogService auditLogService;

    @Override
    public List<Expense> getByOwner(Long ownerId) {
        return expenseRepository.findByOwnerIdOrderByExpenseDateDesc(ownerId);
    }

    @Override
    public List<Expense> getByOwnerAndMonth(Long ownerId, int month, int year) {
        return expenseRepository.findByOwnerIdAndMonthAndYear(ownerId, month, year);
    }

    @Override
    public Expense create(Expense expense) {
        Expense saved = expenseRepository.save(expense);
        auditLogService.logAction(
                "EXPENSE", saved.getId(), "CREATE",
                saved.getOwnerId(), "Owner ID: " + saved.getOwnerId(),
                String.format("Tạo chi phí mới: %s, số tiền: %.0f", saved.getCategory(), saved.getAmount())
        );
        return saved;
    }

    @Override
    public Expense update(Long id, Expense expense) {
        Expense existing = expenseRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Chi phí không tồn tại!"));
        
        String oldChanges = String.format("Cũ: %s, số tiền: %.0f", existing.getCategory(), existing.getAmount());
        
        existing.setCategory(expense.getCategory());
        existing.setDescription(expense.getDescription());
        existing.setAmount(expense.getAmount());
        existing.setExpenseDate(expense.getExpenseDate());
        if (expense.getReceiptImage() != null) existing.setReceiptImage(expense.getReceiptImage());
        
        Expense saved = expenseRepository.save(existing);
        
        auditLogService.logAction(
                "EXPENSE", id, "UPDATE",
                saved.getOwnerId(), "Owner ID: " + saved.getOwnerId(),
                oldChanges + " -> Mới: " + saved.getCategory() + ", số tiền: " + saved.getAmount()
        );
        return saved;
    }

    @Override
    public void delete(Long id) {
        Expense existing = expenseRepository.findById(id).orElse(null);
        if (existing != null) {
            auditLogService.logAction(
                    "EXPENSE", id, "DELETE",
                    existing.getOwnerId(), "Owner ID: " + existing.getOwnerId(),
                    String.format("Xóa chi phí: %s, số tiền: %.0f", existing.getCategory(), existing.getAmount())
            );
            expenseRepository.deleteById(id);
        }
    }

    @Override
    public Map<String, Object> profitReport(Long ownerId, int month, int year) {
        YearMonth ym = YearMonth.of(year, month);
        LocalDate from = ym.atDay(1);
        LocalDate to = ym.atEndOfMonth();

        // Tổng chi phí phát sinh
        Double totalExpense = expenseRepository.sumByOwnerIdAndDateRange(ownerId, from, to);
        if (totalExpense == null) totalExpense = 0.0;

        // Tổng doanh thu từ hóa đơn đã thu trong tháng
        List<?> paidBills = billRepository.findAll().stream()
                .filter(b -> {
                    com.stayhub.api.entity.Bill bill = (com.stayhub.api.entity.Bill) b;
                    return Boolean.TRUE.equals(bill.getIsPaid())
                            && bill.getMonth() == month
                            && bill.getYear() == year;
                }).toList();

        double totalRevenue = paidBills.stream()
                .mapToDouble(b -> {
                    com.stayhub.api.entity.Bill bill = (com.stayhub.api.entity.Bill) b;
                    return bill.getTotalAmount() != null ? bill.getTotalAmount() : 0.0;
                }).sum();

        double netProfit = totalRevenue - totalExpense;

        Map<String, Object> report = new HashMap<>();
        report.put("month", month);
        report.put("year", year);
        report.put("totalRevenue", totalRevenue);
        report.put("totalExpense", totalExpense);
        report.put("netProfit", netProfit);
        report.put("profitMargin", totalRevenue > 0 ? (netProfit / totalRevenue * 100) : 0);
        return report;
    }
}
