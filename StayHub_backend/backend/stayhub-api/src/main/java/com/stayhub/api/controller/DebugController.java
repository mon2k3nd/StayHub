package com.stayhub.api.controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import com.stayhub.api.repository.RentalRequestRepository;
import org.springframework.beans.factory.annotation.Autowired;
@RestController
public class DebugController {
    @Autowired RentalRequestRepository repo;
    @GetMapping("/api/debug/requests")
    public Object get() { return repo.findAll(); }
}
