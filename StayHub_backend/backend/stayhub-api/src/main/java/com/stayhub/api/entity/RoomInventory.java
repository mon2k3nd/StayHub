package com.stayhub.api.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

/**
 * Kiểm kê tài sản riêng trong từng phòng (Room Inventory).
 *
 * <p>Rất quan trọng cho thực tế: khi bàn giao phòng, chủ nhà và khách thuê đối chiếu
 * từng món đồ (điều hòa, bình nóng lạnh, giường, tệm, tủ, khóa cửa...). Mỗi tài sản
 * có hãng, model, số lượng và trạng thái (mới 100% hay đã qua sử dụng) để làm căn cứ
 * bồi thường khi hư hỏng hoặc khi kết thúc hợp đồng.</p>
 */
@Entity
@Table(name = "room_inventory", indexes = {
    @Index(name = "idx_room_inventory_room", columnList = "room_id"),
    @Index(name = "idx_room_inventory_branch", columnList = "branch_id")
})
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@org.hibernate.annotations.SQLRestriction("is_deleted = false")
public class RoomInventory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "room_id", nullable = false)
    private Long roomId;

    @Column(name = "branch_id")
    private Long branchId;

    /** Tên tài sản: Điều hòa, Bình nóng lạnh, Giường, Tệm, Tủ quần áo, Khóa cửa... */
    @Column(name = "asset_name", nullable = false, length = 150)
    private String assetName;

    /** Hãng sản xuất (VD: Daikin, Panasonic). Null nếu không xác định. */
    @Column(name = "brand", length = 100)
    private String brand;

    /** Model cụ thể (VD: FTKB25XVMV). Null nếu không xác định. */
    @Column(name = "model", length = 100)
    private String model;

    /** Số lượng bàn giao. Mặc định 1. */
    @Column(name = "quantity")
    @Builder.Default
    private Integer quantity = 1;

    /**
     * Trạng thái tài sản:
     *  - NEW  : Mới 100%
     *  - USED : Đã qua sử dụng
     *  - BROKEN: Hư hỏng (cần sửa/thay)
     */
    @Column(name = "condition_status", length = 20)
    @Builder.Default
    private String conditionStatus = "NEW"; // NEW | USED | BROKEN

    /** Giá trị ước tính để tính bồi thường khi mất/hư hỏng. */
    @Column(name = "estimated_value")
    private Double estimatedValue;

    /** Ảnh tài sản (JSON array base64 hoặc URL). */
    @Column(name = "images", columnDefinition = "TEXT")
    private String images;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "is_deleted")
    @Builder.Default
    private Boolean isDeleted = false;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
