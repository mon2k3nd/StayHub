package com.stayhub.api.dto.request;

import lombok.Data;
import java.util.List;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.Valid;

@Data
public class BulkCloneRoomRequestDto {

    @NotNull(message = "ID phòng gốc không được để trống")
    private Long sourceRoomId;

    @NotEmpty(message = "Danh sách phòng đích không được để trống")
    @Valid
    private List<TargetRoomConfig> targetRooms;

    @Data
    public static class TargetRoomConfig {
        @NotNull(message = "ID phòng đích không được để trống")
        private Long id;
        private Double price;
        private Double floorArea;
    }
}
