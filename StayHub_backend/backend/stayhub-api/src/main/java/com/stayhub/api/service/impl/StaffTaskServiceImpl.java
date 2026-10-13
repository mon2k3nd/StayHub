package com.stayhub.api.service.impl;

import com.stayhub.api.dto.response.ApiResponse;
import com.stayhub.api.dto.request.StaffTaskRequest;
import com.stayhub.api.dto.request.TaskStatusUpdateRequest;
import com.stayhub.api.dto.response.StaffTaskResponse;
import com.stayhub.api.entity.StaffTask;
import com.stayhub.api.entity.User;
import com.stayhub.api.repository.StaffTaskRepository;
import com.stayhub.api.repository.UserRepository;
import com.stayhub.api.service.StaffTaskService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@lombok.extern.slf4j.Slf4j
public class StaffTaskServiceImpl implements StaffTaskService {

    private final StaffTaskRepository staffTaskRepository;
    private final UserRepository userRepository;

    // staffId -> List of SseEmitters for Staff
    private final Map<Long, List<SseEmitter>> staffEmitters = new ConcurrentHashMap<>();

    @Override
    public SseEmitter registerStaffEmitter(Long staffId) {
        SseEmitter emitter = new SseEmitter(60 * 60 * 1000L); com.stayhub.api.service.SseHeartbeatService.register(emitter); // 1h
        staffEmitters.computeIfAbsent(staffId, k -> new CopyOnWriteArrayList<>()).add(emitter);
        emitter.onCompletion(() -> removeStaffEmitter(staffId, emitter));
        emitter.onTimeout(() -> removeStaffEmitter(staffId, emitter));
        emitter.onError((e) -> removeStaffEmitter(staffId, emitter));
        try {
            emitter.send(SseEmitter.event().name("INIT").data("Connected to staff " + staffId));
        } catch (Exception ignored) { log.warn("Ignored exception in StaffTaskServiceImpl: ", ignored); }
        return emitter;
    }

    private void removeStaffEmitter(Long staffId, SseEmitter emitter) {
        List<SseEmitter> list = staffEmitters.get(staffId);
        if (list != null) {
            list.remove(emitter);
            if (list.isEmpty()) {
                staffEmitters.remove(staffId);
            }
        }
    }

    private void notifyStaff(Long staffId, String eventName, Object data) {
        if (staffId == null) return;
        List<SseEmitter> list = staffEmitters.get(staffId);
        if (list != null) {
            for (SseEmitter emitter : list) {
                try {
                    emitter.send(SseEmitter.event().name(eventName).data(data));
                } catch (Exception e) {
                    removeStaffEmitter(staffId, emitter);
                }
            }
        }
    }

    @Override
    public ApiResponse<StaffTaskResponse> createTask(StaffTaskRequest request) {
        StaffTask task = StaffTask.builder()
                .branchId(request.getBranchId())
                .assignedStaffId(request.getAssignedStaffId())
                .createdById(request.getCreatedById())
                .title(request.getTitle())
                .description(request.getDescription())
                .priority(request.getPriority() != null ? request.getPriority() : "MEDIUM")
                .status("TODO")
                .dueDate(request.getDueDate())
                .build();
        
        task = staffTaskRepository.save(task);
        StaffTaskResponse response = mapToResponse(task);

        if (task.getAssignedStaffId() != null) {
            notifyStaff(task.getAssignedStaffId(), "NEW_TASK", response);
        }

        return ApiResponse.<StaffTaskResponse>builder().success(true).data(response).message("Giao việc thành công").build();
    }

    @Override
    public ApiResponse<List<StaffTaskResponse>> getTasksByBranch(Long branchId, String status) {
        List<StaffTask> tasks;
        if (status != null && !status.isEmpty()) {
            tasks = staffTaskRepository.findByBranchIdAndStatusOrderByCreatedAtDesc(branchId, status);
        } else {
            tasks = staffTaskRepository.findByBranchIdOrderByCreatedAtDesc(branchId);
        }
        List<StaffTaskResponse> responses = tasks.stream().map(this::mapToResponse).collect(Collectors.toList());
        return ApiResponse.<List<StaffTaskResponse>>builder().success(true).data(responses).build();
    }

    @Override
    public ApiResponse<List<StaffTaskResponse>> getTasksByStaff(Long staffId) {
        List<StaffTask> tasks = staffTaskRepository.findByAssignedStaffIdOrderByCreatedAtDesc(staffId);
        List<StaffTaskResponse> responses = tasks.stream().map(this::mapToResponse).collect(Collectors.toList());
        return ApiResponse.<List<StaffTaskResponse>>builder().success(true).data(responses).build();
    }

    @Override
    public ApiResponse<StaffTaskResponse> updateTaskStatus(Long taskId, TaskStatusUpdateRequest request) {
        StaffTask task = staffTaskRepository.findById(taskId).orElse(null);
        if (task == null) {
            return ApiResponse.<StaffTaskResponse>builder().success(false).message("Không tìm thấy công việc").build();
        }

        task.setStatus(request.getStatus());
        task = staffTaskRepository.save(task);
        StaffTaskResponse response = mapToResponse(task);

        return ApiResponse.<StaffTaskResponse>builder().success(true).data(response).message("Cập nhật trạng thái thành công").build();
    }

    @Override
    public ApiResponse<StaffTaskResponse> updateTaskAssignee(Long taskId, Long staffId) {
        StaffTask task = staffTaskRepository.findById(taskId).orElse(null);
        if (task == null) {
            return ApiResponse.<StaffTaskResponse>builder().success(false).message("Không tìm thấy công việc").build();
        }

        task.setAssignedStaffId(staffId);
        task = staffTaskRepository.save(task);
        StaffTaskResponse response = mapToResponse(task);

        notifyStaff(staffId, "NEW_TASK", response);

        return ApiResponse.<StaffTaskResponse>builder().success(true).data(response).message("Cập nhật người phụ trách thành công").build();
    }

    private StaffTaskResponse mapToResponse(StaffTask task) {
        String assignedStaffName = null;
        if (task.getAssignedStaffId() != null) {
            User staff = userRepository.findById(task.getAssignedStaffId()).orElse(null);
            if (staff != null) assignedStaffName = staff.getName();
        }

        String createdByName = null;
        if (task.getCreatedById() != null) {
            User creator = userRepository.findById(task.getCreatedById()).orElse(null);
            if (creator != null) createdByName = creator.getName();
        }

        return StaffTaskResponse.builder()
                .id(task.getId())
                .branchId(task.getBranchId())
                .assignedStaffId(task.getAssignedStaffId())
                .assignedStaffName(assignedStaffName)
                .createdById(task.getCreatedById())
                .createdByName(createdByName)
                .title(task.getTitle())
                .description(task.getDescription())
                .priority(task.getPriority())
                .status(task.getStatus())
                .dueDate(task.getDueDate())
                .createdAt(task.getCreatedAt())
                .updatedAt(task.getUpdatedAt())
                .build();
    }
}
