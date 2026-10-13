package com.stayhub.api.service;

import com.stayhub.api.entity.Expense;
import java.util.List;
import java.util.Map;

public interface ExpenseService {
    List<Expense> getByOwner(Long ownerId);
    List<Expense> getByOwnerAndMonth(Long ownerId, int month, int year);
    Expense create(Expense expense);
    Expense update(Long id, Expense expense);
    void delete(Long id);
    Map<String, Object> profitReport(Long ownerId, int month, int year);
}
