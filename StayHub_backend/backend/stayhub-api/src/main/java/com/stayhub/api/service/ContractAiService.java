package com.stayhub.api.service;

import com.stayhub.api.entity.ElectronicContract;
import reactor.core.publisher.Mono;

public interface ContractAiService {
    Mono<String> generateAiAppendix(Long rentalRequestId, Long roomId, Long tenantId, Long ownerId);
    Mono<String> generateAndUploadPdf(ElectronicContract contract);
}
