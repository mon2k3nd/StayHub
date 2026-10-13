package com.stayhub.api.repository;

import com.stayhub.api.entity.Expense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;

@Repository
public interface ExpenseRepository extends JpaRepository<Expense, Long> {
    List<Expense> findByOwnerIdOrderByExpenseDateDesc(Long ownerId);
    List<Expense> findByOwnerIdAndBranchId(Long ownerId, Long branchId);

    @Query("SELECT SUM(e.amount) FROM Expense e WHERE e.ownerId = :ownerId AND e.expenseDate BETWEEN :from AND :to")
    Double sumByOwnerIdAndDateRange(Long ownerId, LocalDate from, LocalDate to);

    @Query("SELECT e FROM Expense e WHERE e.ownerId = :ownerId AND MONTH(e.expenseDate) = :month AND YEAR(e.expenseDate) = :year")
    List<Expense> findByOwnerIdAndMonthAndYear(Long ownerId, int month, int year);
}
