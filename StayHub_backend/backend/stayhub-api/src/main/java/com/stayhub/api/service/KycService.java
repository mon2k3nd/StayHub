package com.stayhub.api.service;

import com.stayhub.api.entity.KycRequest;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;

public interface KycService {
    KycRequest submitRequest(Long userId, String branchName, String businessAddress,
                             MultipartFile cccdFront, MultipartFile cccdBack, MultipartFile businessLicense);
    List<KycRequest> getPending();
    void approve(Long kycId);
    void reject(Long kycId, String reason);
}
