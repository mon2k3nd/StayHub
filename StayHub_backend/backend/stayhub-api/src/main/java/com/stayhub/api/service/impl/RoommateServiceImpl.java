package com.stayhub.api.service.impl;

import com.stayhub.api.entity.Roommate;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.RoommateRepository;
import com.stayhub.api.service.RoommateService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RoommateServiceImpl implements RoommateService {

    private final RoommateRepository roommateRepository;

    @Override
    public List<Roommate> getByContract(Long contractId) {
        return roommateRepository.findByContractIdAndIsActiveTrue(contractId);
    }

    @Override
    public Roommate addRoommate(Roommate roommate) {
        roommate.setIsActive(true);
        if (roommate.getCheckInDate() == null) {
            roommate.setCheckInDate(LocalDate.now());
        }
        return roommateRepository.save(roommate);
    }

    @Override
    public void checkout(Long roommateId) {
        Roommate r = roommateRepository.findById(roommateId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người ở cùng ID: " + roommateId));
        r.setIsActive(false);
        r.setCheckOutDate(LocalDate.now());
        roommateRepository.save(r);
    }
}
