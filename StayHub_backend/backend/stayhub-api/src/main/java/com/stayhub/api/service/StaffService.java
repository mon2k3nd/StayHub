package com.stayhub.api.service;

import com.stayhub.api.entity.StaffAssignment;
import com.stayhub.api.entity.User;
import java.util.List;

public interface StaffService {
    User createStaff(String name, String phoneNumber, String password, Long ownerId, List<Long> branchIds);
    List<User> getStaffByOwner(Long ownerId);
    List<StaffAssignment> getAssignments(Long staffId);
    StaffAssignment updateSchedule(Long assignmentId, String schedule);
    StaffAssignment updatePermissions(Long assignmentId, String permissions, String staffRole);
    void removeStaff(Long staffId, Long ownerId);
    void changeStatus(Long staffId, User.UserStatus status, String reason);
    void assignBranches(Long staffId, Long ownerId, List<Long> branchIds);
    void settleWallet(Long staffId, Double amount);
}
