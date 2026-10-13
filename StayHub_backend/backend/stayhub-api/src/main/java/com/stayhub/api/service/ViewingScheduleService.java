package com.stayhub.api.service;

import com.stayhub.api.entity.RequestStatus;
import com.stayhub.api.entity.ViewingSchedule;
import com.stayhub.api.repository.ViewingScheduleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class ViewingScheduleService {

    @Autowired
    private ViewingScheduleRepository repository;

    @Transactional
    public ViewingSchedule createSchedule(ViewingSchedule schedule) {
        schedule.setStatus(RequestStatus.PENDING);
        return repository.save(schedule);
    }

    public List<ViewingSchedule> getSchedulesForOwner(Long ownerId) {
        return repository.findByOwnerIdOrderByCreatedAtDesc(ownerId);
    }

    public List<ViewingSchedule> getSchedulesForTenant(Long tenantId) {
        return repository.findByTenantIdOrderByCreatedAtDesc(tenantId);
    }

    public ViewingSchedule getById(Long id) {
        return repository.findById(id)
            .orElseThrow(() -> new RuntimeException("Viewing Schedule not found with id: " + id));
    }

    @Transactional
    public ViewingSchedule updateStatus(Long id, RequestStatus status) {
        Optional<ViewingSchedule> opt = repository.findById(id);
        if (opt.isPresent()) {
            ViewingSchedule schedule = opt.get();
            schedule.setStatus(status);
            return repository.save(schedule);
        }
        throw new RuntimeException("Viewing Schedule not found with id: " + id);
    }
}
