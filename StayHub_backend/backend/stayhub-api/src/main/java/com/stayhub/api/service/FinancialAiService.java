package com.stayhub.api.service;

public interface FinancialAiService {
    String getFinancialAdvice(Long ownerId, Integer month, Integer year);
}
