package com.stayhub.api.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.stayhub.api.dto.ChecklistItemDto;
import com.stayhub.api.dto.HousekeepingTaskDto;
import com.stayhub.api.entity.HousekeepingTask;
import com.stayhub.api.repository.HousekeepingTaskRepository;
import com.stayhub.api.service.HousekeepingService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HousekeepingServiceImpl implements HousekeepingService {

    private final HousekeepingTaskRepository repository;
    private final ObjectMapper objectMapper;

    @Override
    public List<HousekeepingTaskDto> getTasksByBranch(Long branchId) {
        List<HousekeepingTask> tasks = repository.findByBranchId(branchId);
        
        // Seed default tasks if empty (for testing based on your prompt)
        if (tasks.isEmpty()) {
            tasks = seedDefaultTasks(branchId);
        }

        return tasks.stream().map(this::mapToDto).collect(Collectors.toList());
    }

    @Override
    public HousekeepingTaskDto updateTaskStatus(Long taskId, String status) {
        HousekeepingTask task = repository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));
        task.setStatus(status);
        repository.save(task);
        return mapToDto(task);
    }

    @Override
    public HousekeepingTaskDto updateChecklist(Long taskId, List<ChecklistItemDto> checklist) {
        HousekeepingTask task = repository.findById(taskId)
                .orElseThrow(() -> new RuntimeException("Task not found"));
        try {
            task.setChecklistData(objectMapper.writeValueAsString(checklist));
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize checklist", e);
        }
        repository.save(task);
        return mapToDto(task);
    }

    private HousekeepingTaskDto mapToDto(HousekeepingTask task) {
        List<ChecklistItemDto> checklist = new ArrayList<>();
        if (task.getChecklistData() != null && !task.getChecklistData().isEmpty()) {
            try {
                checklist = objectMapper.readValue(task.getChecklistData(), new TypeReference<List<ChecklistItemDto>>() {});
            } catch (JsonProcessingException e) {
                // Ignore parsing errors for now
            }
        }

        return HousekeepingTaskDto.builder()
                .id(task.getId())
                .branchId(task.getBranchId())
                .roomId(task.getRoomId())
                .roomName(task.getRoomName())
                .type(task.getTaskType())
                .status(task.getStatus())
                .dueTime(task.getDueTime())
                .checklist(checklist)
                .build();
    }

    private List<HousekeepingTask> seedDefaultTasks(Long branchId) {
        List<HousekeepingTask> seedTasks = new ArrayList<>();
        
        try {
            // Task 1
            List<ChecklistItemDto> cl1 = List.of(
                    new ChecklistItemDto("Thay ga trải giường & gối", true, true),
                    new ChecklistItemDto("Lau sàn nhà", true, true),
                    new ChecklistItemDto("Vệ sinh nhà vệ sinh", true, true),
                    new ChecklistItemDto("Chụp ảnh phòng sau khi dọn", true, true)
            );
            HousekeepingTask t1 = new HousekeepingTask();
            t1.setBranchId(branchId);
            t1.setRoomId(101L);
            t1.setRoomName("Phòng 101");
            t1.setTaskType("cleaning");
            t1.setStatus("DONE");
            t1.setDueTime("14:00");
            t1.setChecklistData(objectMapper.writeValueAsString(cl1));
            seedTasks.add(t1);

            // Task 2
            List<ChecklistItemDto> cl2 = List.of(
                    new ChecklistItemDto("Kiểm tra chốt cửa và khóa", true, true),
                    new ChecklistItemDto("Chụp ảnh hiện trạng phòng", true, true),
                    new ChecklistItemDto("Thu chìa khóa từ khách", true, false)
            );
            HousekeepingTask t2 = new HousekeepingTask();
            t2.setBranchId(branchId);
            t2.setRoomId(203L);
            t2.setRoomName("Phòng 203");
            t2.setTaskType("checkOut");
            t2.setStatus("IN_PROGRESS");
            t2.setDueTime("10:00");
            t2.setChecklistData(objectMapper.writeValueAsString(cl2));
            seedTasks.add(t2);

            // Task 3
            List<ChecklistItemDto> cl3 = List.of(
                    new ChecklistItemDto("Bàn giao chìa khóa", true, false),
                    new ChecklistItemDto("Ký biên bản", true, false)
            );
            HousekeepingTask t3 = new HousekeepingTask();
            t3.setBranchId(branchId);
            t3.setRoomId(305L);
            t3.setRoomName("Phòng 305");
            t3.setTaskType("checkIn");
            t3.setStatus("PENDING");
            t3.setDueTime("15:00");
            t3.setChecklistData(objectMapper.writeValueAsString(cl3));
            seedTasks.add(t3);

            return repository.saveAll(seedTasks);

        } catch (Exception e) {
            return seedTasks;
        }
    }
}
