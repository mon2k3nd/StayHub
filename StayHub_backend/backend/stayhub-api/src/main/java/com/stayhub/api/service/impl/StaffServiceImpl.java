package com.stayhub.api.service.impl;

import com.stayhub.api.entity.*;
import com.stayhub.api.exception.ResourceNotFoundException;
import com.stayhub.api.repository.*;
import com.stayhub.api.service.StaffService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StaffServiceImpl implements StaffService {

    private final UserRepository userRepository;
    private final StaffAssignmentRepository staffAssignmentRepository;
    private final OwnerTenantMappingRepository ownerTenantMappingRepository;
    private final BranchRepository branchRepository;
    private final StaffWalletRepository staffWalletRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public User createStaff(String name, String phoneNumber, String password,
                            Long ownerId, List<Long> branchIds) {
        if (userRepository.findByPhoneNumber(phoneNumber).isPresent()) {
            throw new IllegalStateException("Số điện thoại đã tồn tại trong hệ thống!");
        }

        User staff = User.builder()
                .name(name)
                .phoneNumber(phoneNumber)
                .email("staff_" + phoneNumber + "@stayhub.com")
                .passwordHash(passwordEncoder.encode(password))
                .roleId("STAFF")
                .status(User.UserStatus.PENDING_VERIFICATION)
                .accountStatus("ACTIVE")
                .build();
        User savedStaff = userRepository.save(staff);

        // Liên kết owner - staff
        OwnerTenantMapping mapping = new OwnerTenantMapping();
        mapping.setOwnerId(ownerId);
        mapping.setTenantId(savedStaff.getId());
        mapping.setMappingType("STAFF");
        ownerTenantMappingRepository.save(mapping);

        // Nếu branchIds rỗng → tự động gán vào TẤT CẢ khu trọ của chủ nhà
        List<Long> effectiveBranchIds = branchIds;
        if (branchIds == null || branchIds.isEmpty()) {
            effectiveBranchIds = branchRepository.findByOwnerId(ownerId)
                    .stream()
                    .map(Branch::getId)
                    .collect(Collectors.toList());
        }

        // Phân công theo từng dãy trọ
        if (effectiveBranchIds != null) {
            for (Long branchId : effectiveBranchIds) {
                StaffAssignment assignment = StaffAssignment.builder()
                        .staffId(savedStaff.getId())
                        .ownerId(ownerId)
                        .branchId(branchId)
                        .isActive(true)
                        .build();
                staffAssignmentRepository.save(assignment);
            }
        }

        return savedStaff;
    }

    @Override
    public List<User> getStaffByOwner(Long ownerId) {
        List<OwnerTenantMapping> mappings = ownerTenantMappingRepository.findByOwnerIdAndMappingType(ownerId, "STAFF");
        List<Long> staffIds = mappings.stream()
                .map(OwnerTenantMapping::getTenantId)
                .distinct()
                .collect(Collectors.toList());
        
        // Cần thiết cho các staff cũ chưa có mappingType="STAFF" nhưng có assignment
        List<StaffAssignment> assignments = staffAssignmentRepository.findByOwnerIdAndIsActiveTrue(ownerId);
        staffIds.addAll(assignments.stream().map(StaffAssignment::getStaffId).collect(Collectors.toList()));
        staffIds = staffIds.stream().distinct().collect(Collectors.toList());

        List<User> users = (List<User>) userRepository.findAllById(staffIds);
        for (User u : users) {
            u.setAssignments(staffAssignmentRepository.findByStaffIdAndIsActiveTrue(u.getId()));
            staffWalletRepository.findByStaffId(u.getId()).ifPresent(u::setWallet);
        }
        return users;
    }

    @Override
    @Transactional
    public List<StaffAssignment> getAssignments(Long staffId) {
        List<StaffAssignment> assignments = staffAssignmentRepository.findByStaffIdAndIsActiveTrue(staffId);
        
        // Nếu nhân viên chưa có phân công nào, tự động tìm chủ nhà và gán vào tất cả dãy trọ của chủ nhà
        if (assignments.isEmpty()) {
            List<OwnerTenantMapping> mappings = ownerTenantMappingRepository.findByTenantId(staffId);
            if (!mappings.isEmpty()) {
                Long ownerId = mappings.get(0).getOwnerId();
                List<Branch> branches = branchRepository.findByOwnerId(ownerId);
                for (Branch branch : branches) {
                    StaffAssignment assignment = StaffAssignment.builder()
                            .staffId(staffId)
                            .ownerId(ownerId)
                            .branchId(branch.getId())
                            .isActive(true)
                            .permissions("{}") // Dùng "{}" để frontend tự hiểu là toàn quyền (fullAccess)
                            .build();
                    staffAssignmentRepository.save(assignment);
                    assignments.add(assignment);
                }
            }
        }
        return assignments;
    }

    @Override
    public StaffAssignment updateSchedule(Long assignmentId, String schedule) {
        StaffAssignment assignment = staffAssignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phân công ID: " + assignmentId));
        assignment.setWorkSchedule(schedule);
        return staffAssignmentRepository.save(assignment);
    }

    @Override
    @Transactional
    public void removeStaff(Long staffId, Long ownerId) {
        changeStatus(staffId, User.UserStatus.RESIGNED, "Xóa nhân viên (không rõ lý do)");
    }

    @Override
    @Transactional
    public void changeStatus(Long staffId, User.UserStatus status, String reason) {
        User staff = userRepository.findById(staffId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy nhân viên"));
        
        staff.setStatus(status);
        if (reason != null) {
            staff.setResignReason(reason);
        }
        userRepository.save(staff);

        // Nếu nghỉ việc hoặc khóa, có thể vô hiệu hóa các phân công
        if (status == User.UserStatus.RESIGNED || status == User.UserStatus.LOCKED) {
            staffAssignmentRepository.findByStaffIdAndIsActiveTrue(staffId).forEach(a -> {
                a.setIsActive(false);
                staffAssignmentRepository.save(a);
            });
        }
    }

    @Override
    public StaffAssignment updatePermissions(Long assignmentId, String permissions, String staffRole) {
        StaffAssignment assignment = staffAssignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phân công ID: " + assignmentId));
        if (permissions != null) assignment.setPermissions(permissions);
        if (staffRole != null) assignment.setStaffRole(staffRole);
        return staffAssignmentRepository.save(assignment);
    }

    @Override
    @Transactional
    public void assignBranches(Long staffId, Long ownerId, List<Long> branchIds) {
        // Nếu branchIds rỗng → tự động gán vào TẤT CẢ khu trọ của chủ nhà
        List<Long> effectiveBranchIds = branchIds;
        if (branchIds == null || branchIds.isEmpty()) {
            effectiveBranchIds = branchRepository.findByOwnerId(ownerId)
                    .stream()
                    .map(Branch::getId)
                    .collect(Collectors.toList());
        }
        if (effectiveBranchIds == null) return;

        // Lấy các branchId đã được phân công để tránh trùng lặp
        List<Long> existingBranchIds = staffAssignmentRepository
                .findByStaffIdAndIsActiveTrue(staffId)
                .stream()
                .map(StaffAssignment::getBranchId)
                .collect(Collectors.toList());

        for (Long branchId : effectiveBranchIds) {
            if (!existingBranchIds.contains(branchId)) {
                StaffAssignment assignment = StaffAssignment.builder()
                        .staffId(staffId)
                        .ownerId(ownerId)
                        .branchId(branchId)
                        .isActive(true)
                        .build();
                staffAssignmentRepository.save(assignment);
            }
        }
    }

    @Override
    @Transactional
    public void settleWallet(Long staffId, Double amount) {
        StaffWallet wallet = staffWalletRepository.findByStaffId(staffId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy ví nhân viên"));
        
        double currentDebt = wallet.getCashSpent() != null ? wallet.getCashSpent() : 0.0;
        double newDebt = currentDebt - amount;
        if (newDebt < 0) newDebt = 0.0;
        
        wallet.setCashSpent(newDebt);
        staffWalletRepository.save(wallet);
    }
}
