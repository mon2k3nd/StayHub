package com.stayhub.api.service;

import com.stayhub.api.entity.Roommate;
import java.util.List;

public interface RoommateService {
    List<Roommate> getByContract(Long contractId);
    Roommate addRoommate(Roommate roommate);
    void checkout(Long roommateId);
}
