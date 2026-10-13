package com.stayhub.api.service;

import com.stayhub.api.dto.request.BranchGroupMessageRequest;
import com.stayhub.api.dto.response.BranchGroupMessageDto;

import java.util.List;

public interface BranchGroupChatService {
    List<BranchGroupMessageDto> getHistory(Long branchId);
    BranchGroupMessageDto sendMessage(Long branchId, Long senderId, BranchGroupMessageRequest request);
    void sendSystemMessage(Long branchId, String content);
}
