package com.stayhub.api.controller;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.entity.Expense;
import com.stayhub.api.service.ExpenseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/v1/expenses")
@RequiredArgsConstructor
public class ExpenseController {

    private final ExpenseService expenseService;

    @GetMapping("/owner/{ownerId}")
    public ResponseEntity<ApiResponse<List<Expense>>> getByOwner(@PathVariable Long ownerId, org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return ResponseEntity.status(401).build();
        Long authUserId = (Long) auth.getPrincipal();
        if (!authUserId.equals(ownerId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))) return ResponseEntity.status(403).build();
        return ResponseEntity.ok(ApiResponse.<List<Expense>>builder()
                .success(true).message("Thành công!")
                .data(expenseService.getByOwner(ownerId)).build());
    }

    @GetMapping("/owner/{ownerId}/monthly")
    public ResponseEntity<ApiResponse<List<Expense>>> getByOwnerAndMonth(
            @PathVariable Long ownerId,
            @RequestParam int month,
            @RequestParam int year,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return ResponseEntity.status(401).build();
        Long authUserId = (Long) auth.getPrincipal();
        if (!authUserId.equals(ownerId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))) return ResponseEntity.status(403).build();
        return ResponseEntity.ok(ApiResponse.<List<Expense>>builder()
                .success(true).message("Thành công!")
                .data(expenseService.getByOwnerAndMonth(ownerId, month, year)).build());
    }

/*
    @PostMapping
    public ResponseEntity<ApiResponse<Expense>> create(@RequestBody Expense expense) {
        try {
            return ResponseEntity.ok(ApiResponse.<Expense>builder()
                    .success(true).message("Ghi chi phí thành công!")
                    .data(expenseService.create(expense)).build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Expense>builder().success(false).message(e.getMessage()).build());
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Expense>> update(@PathVariable Long id, @RequestBody Expense expense) {
        try {
            return ResponseEntity.ok(ApiResponse.<Expense>builder()
                    .success(true).message("Cập nhật chi phí thành công!")
                    .data(expenseService.update(id, expense)).build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Expense>builder().success(false).message(e.getMessage()).build());
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
        try {
            expenseService.delete(id);
            return ResponseEntity.ok(ApiResponse.<Void>builder().success(true).message("Đã xóa chi phí!").build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Void>builder().success(false).message(e.getMessage()).build());
        }
    }
*/

    /** Báo cáo lợi nhuận ròng theo tháng */
    @GetMapping("/owner/{ownerId}/profit-report")
    public ResponseEntity<ApiResponse<Map<String, Object>>> profitReport(
            @PathVariable Long ownerId,
            @RequestParam int month,
            @RequestParam int year,
            org.springframework.security.core.Authentication auth) {
        if (auth == null || auth.getPrincipal() == null) return ResponseEntity.status(401).build();
        Long authUserId = (Long) auth.getPrincipal();
        if (!authUserId.equals(ownerId) && auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))) return ResponseEntity.status(403).build();
        try {
            return ResponseEntity.ok(ApiResponse.<Map<String, Object>>builder()
                    .success(true).message("Thành công!")
                    .data(expenseService.profitReport(ownerId, month, year)).build());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(ApiResponse.<Map<String, Object>>builder().success(false).message(e.getMessage()).build());
        }
    }
}
