package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Expense;
import com.stayhub.api.service.ExpenseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/expenses")
@RequiredArgsConstructor
public class V1ExpenseController {

    private final ExpenseService expenseService;
    private final com.stayhub.api.repository.ExpenseRepository expenseRepository;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Expense>>> getExpenses(
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year,
            Authentication auth) {
        
        Long ownerId = Long.parseLong(auth.getPrincipal().toString());
        List<Expense> expenses;
        if (month != null && year != null) {
            expenses = expenseService.getByOwnerAndMonth(ownerId, month, year);
        } else {
            expenses = expenseService.getByOwner(ownerId);
        }
        return ResponseEntity.ok(ApiResponse.ok(expenses));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Expense>> createExpense(
            @RequestBody Expense expense,
            Authentication auth) {
        Long ownerId = Long.parseLong(auth.getPrincipal().toString());
        expense.setOwnerId(ownerId);
        Expense created = expenseService.create(expense);
        return ResponseEntity.status(201).body(ApiResponse.ok(created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Expense>> updateExpense(
            @PathVariable Long id,
            @RequestBody Expense expense,
            Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = Long.parseLong(auth.getPrincipal().toString());
        
        Expense existing = expenseRepository.findById(id)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Không tìm thấy chi phí"));
        
        if (!existing.getOwnerId().equals(userId)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền sửa chi phí này");
        }
                
        Expense updated = expenseService.update(id, expense);
        return ResponseEntity.ok(ApiResponse.ok(updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteExpense(@PathVariable Long id, Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED);
        Long userId = Long.parseLong(auth.getPrincipal().toString());
        
        Expense existing = expenseRepository.findById(id)
                .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.NOT_FOUND, "Không tìm thấy chi phí"));
                
        if (!existing.getOwnerId().equals(userId)) {
            throw new org.springframework.web.server.ResponseStatusException(org.springframework.http.HttpStatus.FORBIDDEN, "Bạn không có quyền xóa chi phí này");
        }
        
        expenseService.delete(id);
        return ResponseEntity.ok(ApiResponse.ok(null));
    }
}
