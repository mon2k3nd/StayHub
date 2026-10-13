package com.stayhub.api.repository;

import com.stayhub.api.dto.request.RoomSearchCriteria;
import com.stayhub.api.entity.Room;
import com.stayhub.api.entity.RoomPost;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

/**
 * Specification cho tìm kiếm phòng công khai (guest marketplace).
 *
 * <p>Mọi predicate đều được dựng trên một {@code Join<RoomPost, Room>} INNER,
 * nên chỉ những tin đăng có phòng hợp lệ mới lọt qua. Điều kiện nền tảng:</p>
 * <ul>
 *   <li>{@code room_posts.status = 'ACTIVE'}</li>
 *   <li>{@code rooms.status = 'TRONG'} (còn trống)</li>
 *   <li>{@code rooms.is_deleted = false}</li>
 * </ul>
 *
 * không phải count).</p>
 */
public final class RoomPostSpecification {

    private RoomPostSpecification() {
        // utility class
    }

    /**
     * Dựng specification từ tiêu chí tìm kiếm.
     *
     * @param criteria tiêu chí (có thể null → chỉ lọc mặc định)
     * @return specification an toàn cho cả query lấy dữ liệu lẫn count
     */
    public static Specification<RoomPost> fromCriteria(RoomSearchCriteria criteria) {
        RoomSearchCriteria c = criteria != null ? criteria : new RoomSearchCriteria();

        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // ── Điều kiện nền tảng ────────────────────────────────────────────
            predicates.add(cb.equal(root.get("status"), "ACTIVE"));

            Join<RoomPost, Room> room = root.join("room", JoinType.INNER);
            // Phòng còn trống: TRONG (đang cho thuê) hoặc SAP_TRONG (sắp trống).
            // Trước đây chỉ lọc TRONG nên bỏ sót phòng sắp trống — guest không thấy.
            predicates.add(room.get("status").in(
                    com.stayhub.api.entity.RoomStatus.TRONG,
                    com.stayhub.api.entity.RoomStatus.SAP_TRONG));
            // isDeleted có thể null trong dữ liệu cũ → coi null = chưa xoá.
            predicates.add(cb.or(
                    cb.isNull(room.get("isDeleted")),
                    cb.isFalse(room.get("isDeleted"))));

            // ── Giá thuê ──────────────────────────────────────────────────────
            // Ưu tiên giá của tin đăng (renting_price); nếu null thì dùng giá phòng.
            if (c.getMinPrice() != null) {
                predicates.add(cb.ge(
                        cb.coalesce(root.get("rentingPrice"), room.get("price")),
                        c.getMinPrice()));
            }
            if (c.getMaxPrice() != null) {
                predicates.add(cb.le(
                        cb.coalesce(root.get("rentingPrice"), room.get("price")),
                        c.getMaxPrice()));
            }

            // ── Diện tích ─────────────────────────────────────────────────────
            if (c.getMinArea() != null) {
                predicates.add(cb.ge(room.get("floorArea"), c.getMinArea()));
            }
            if (c.getMaxArea() != null) {
                predicates.add(cb.le(room.get("floorArea"), c.getMaxArea()));
            }

            // ── Loại phòng ────────────────────────────────────────────────────
            // QUY TẮC: lọc theo MÃ (id mô hình), KHÔNG lọc theo chữ/nhãn.
            // `rooms.room_sub_type` là cột canonical lưu MÃ (vd PHONG_TRO).
            // Mọi mã đồng nghĩa (alias) được quy về cùng một tập mã canonical
            // rồi so khớp BẰNG (equal) — tuyệt đối không dùng LIKE '%...%' vì
            // sẽ khớp nhầm (vd "CĂN HỘ" khớp cả "CĂN HỘ MINI", "CĂN HỘ DỊCH VỤ").
            if (c.getRoomTypes() != null && !c.getRoomTypes().isEmpty()) {
                java.util.Set<String> canonicalCodes = new java.util.LinkedHashSet<>();
                for (String t : c.getRoomTypes()) {
                    if (t == null || t.isBlank()) continue;
                    canonicalCodes.addAll(
                            com.stayhub.api.util.RoomTypeCodes.canonicalCodes(t));
                }
                if (!canonicalCodes.isEmpty()) {
                    predicates.add(cb.upper(room.get("roomSubType"))
                            .in(canonicalCodes));
                }
            }

            // ── Số phòng ngủ ──────────────────────────────────────────────────
            if (c.getBedrooms() != null) {
                // 5 nghĩa là "5+" → dùng >= thay vì =.
                if (c.getBedrooms() >= 5) {
                    predicates.add(cb.ge(room.get("bedrooms"), 5));
                } else {
                    predicates.add(cb.equal(room.get("bedrooms"), c.getBedrooms()));
                }
            }

            // ── Số giường ─────────────────────────────────────────────────────
            if (c.getBeds() != null) {
                if (c.getBeds() >= 5) {
                    predicates.add(cb.ge(room.get("beds"), 5));
                } else {
                    predicates.add(cb.equal(room.get("beds"), c.getBeds()));
                }
            }

            // ── Số phòng tắm / WC ─────────────────────────────────────────────
            if (c.getBathrooms() != null) {
                if (c.getBathrooms() >= 5) {
                    predicates.add(cb.ge(room.get("bathrooms"), 5));
                } else {
                    predicates.add(cb.equal(room.get("bathrooms"), c.getBathrooms()));
                }
            }

            // ── Số người tối đa ───────────────────────────────────────────────
            // Lọc "chứa được ít nhất N người" → dùng >=.
            if (c.getMaxGuests() != null) {
                predicates.add(cb.ge(room.get("maxGuests"), c.getMaxGuests()));
            }

            // ── Hình thức sử dụng ─────────────────────────────────────────────
            // SHARED  → ở ghép: dùng WC chung (is_shared_wc = true)
            // PRIVATE → phòng riêng khép kín: WC riêng (bathroom_type = 'RIENG')
            // WHOLE   → thuê nguyên căn: KHÔNG lọc theo WC (giữ đúng ngữ nghĩa,
            //           trước đây gộp WHOLE=PRIVATE nên lọc sai).
            if (c.getUsageType() != null) {
                switch (c.getUsageType().toUpperCase()) {
                    case "SHARED" -> predicates.add(cb.isTrue(room.get("isSharedWc")));
                    case "PRIVATE" -> predicates.add(cb.equal(
                            cb.upper(room.get("bathroomType")), "RIENG"));
                    case "WHOLE" -> { /* nguyên căn: không ràng buộc WC */ }
                    default -> { /* bỏ qua giá trị lạ */ }
                }
            }

            // ── Hướng phòng ───────────────────────────────────────────────────
            if (c.getDirection() != null && !c.getDirection().isBlank()) {
                predicates.add(cb.equal(
                        cb.upper(room.get("direction")),
                        c.getDirection().toUpperCase()));
            }

            // ── Đặc điểm phòng ────────────────────────────────────────────────
            // Dữ liệu cũ có thể null → coi null là "không có" (khớp mặc định entity).
            if (Boolean.TRUE.equals(c.getHasWindow())) {
                predicates.add(cb.isTrue(room.get("hasWindow")));
            }
            if (Boolean.TRUE.equals(c.getHasBalcony())) {
                predicates.add(cb.isTrue(room.get("hasBalcony")));
            }
            if (Boolean.TRUE.equals(c.getPrivateBathroom())) {
                predicates.add(cb.equal(
                        cb.upper(room.get("bathroomType")), "RIENG"));
            }

            // ── Chỉ tin có khuyến mãi ─────────────────────────────────────────
            if (Boolean.TRUE.equals(c.getOnlyPromotion())) {
                predicates.add(cb.isTrue(root.get("hasPromotion")));
            }

            // ── Tiện ích / nội thất (AND — phải chứa TẤT CẢ mã) ───────────────
            // `furniture` là TEXT chứa JSON array, ví dụ ["AC","WIFI"].
            // Dùng LIKE không phân biệt hoa/thường.
            //
            // BUGFIX: trước đây dùng `cb.or(like("%\"CODE\"%"), like("%CODE%"))`.
            // Vế thứ hai (`%CODE%`) là SUPERSET của vế thứ nhất nên `or` vô nghĩa,
            // và tệ hơn: khớp SUBSTRING không có ranh giới token → sai kết quả.
            // Ví dụ lọc tiện ích "AC" sẽ khớp cả "MÁY_LẠNH" (không có), nhưng
            // "BAN_CONG" khớp "BAN_CONG_RIENG", và "AC" khớp bất kỳ chuỗi nào
            // chứa "AC" (vd "PEACE", "FACTORY"). Nay khớp CHÍNH XÁC theo token
            // JSON: `"CODE"` (có ngoặc kép) HOẶC `,CODE,`/`[CODE,`/`,CODE]`
            // (dữ liệu nhập tay không ngoặc kép) — luôn có ranh giới dấu phẩy.
            if (c.getAmenities() != null && !c.getAmenities().isEmpty()) {
                for (String amenity : c.getAmenities()) {
                    if (amenity == null || amenity.isBlank()) continue;
                    String code = amenity.trim().toUpperCase();
                    // BUGFIX: bộ mẫu LIKE trước đây KHÔNG bao phủ hết các vị trí
                    // phần tử trong mảng. Với JSON chuẩn `["AC","WIFI"]`:
                    //   - `%"AC"%`  → khớp (đã có)
                    //   - `%[AC,%`  → KHÔNG khớp (JSON là `["AC",` — có dấu ngoặc kép)
                    //   - `%,AC]%`  → KHÔNG khớp (JSON là `,"AC"]`)
                    // Với CSV `AC,WIFI` (dữ liệu nhập tay):
                    //   - `%"AC"%`  → KHÔNG khớp
                    //   - `%[AC,%`  → KHÔNG khớp (không có `[`)
                    //   - `%,AC]%`  → KHÔNG khớp (không có `]`)
                    //   - `%,AC,%`  → chỉ khớp phần tử GIỮA, trượt phần tử ĐẦU/CUỐI
                    // Hệ quả: lọc tiện ích trượt với phần tử đầu/cuối của CSV và
                    // với mọi phần tử JSON trừ khi trùng mẫu `%"CODE"%`. Nay bổ
                    // sung đủ 6 mẫu có RANH GIỚI token cho cả JSON lẫn CSV:
                    //   JSON: `"CODE"` (bất kỳ vị trí), `["CODE"` (đầu), `"CODE"]` (cuối)
                    //   CSV : `,CODE,` (giữa), `[CODE,`/`,CODE]` (đầu/cuối không ngoặc)
                    predicates.add(cb.or(
                            // JSON: phần tử bất kỳ — ["AC","WIFI"] hoặc ["WIFI","AC"]
                            cb.like(cb.upper(room.get("furniture")), "%\"" + code + "\"%"),
                            // JSON: phần tử ĐẦU — ["AC","WIFI"]
                            cb.like(cb.upper(room.get("furniture")), "%[\"" + code + "\"%"),
                            // JSON: phần tử CUỐI — ["WIFI","AC"]
                            cb.like(cb.upper(room.get("furniture")), "%\"" + code + "\"]%"),
                            // CSV: phần tử GIỮA — AC,WIFI,TV
                            cb.like(cb.upper(room.get("furniture")), "%," + code + ",%"),
                            // CSV: phần tử ĐẦU — AC,WIFI
                            cb.like(cb.upper(room.get("furniture")), "%[" + code + ",%"),
                            // CSV: phần tử CUỐI — WIFI,AC
                            cb.like(cb.upper(room.get("furniture")), "%," + code + "]%")));
                }
            }

            // ── Tỉnh / Thành phố ──────────────────────────────────────────────
            if (c.getProvince() != null && !c.getProvince().isBlank()) {
                String p = c.getProvince().trim().toLowerCase()
                        .replace("thành phố ", "").replace("tỉnh ", "");
                String needle = "%" + p + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(room.get("address")), needle),
                        cb.like(cb.lower(room.get("addressOld")), needle)));
            }

            // ── Quận / Huyện ──────────────────────────────────────────────────
            if (c.getDistrict() != null && !c.getDistrict().isBlank()) {
                String d = c.getDistrict().trim().toLowerCase()
                        .replace("quận ", "").replace("huyện ", "").replace("thị xã ", "").replace("thành phố ", "");
                String needle = "%" + d + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(room.get("address")), needle),
                        cb.like(cb.lower(room.get("addressOld")), needle)));
            }

            // ── Phường / Xã ───────────────────────────────────────────────────
            if (c.getWard() != null && !c.getWard().isBlank()) {
                String w = c.getWard().trim().toLowerCase()
                        .replace("phường ", "").replace("xã ", "").replace("thị trấn ", "");
                String needle = "%" + w + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(room.get("address")), needle),
                        cb.like(cb.lower(room.get("addressOld")), needle)));
            }

            // ── Từ khoá tự do ─────────────────────────────────────────────────
            if (c.getKeyword() != null && !c.getKeyword().isBlank()) {
                String needle = "%" + c.getKeyword().trim().toLowerCase() + "%";
                // BUGFIX: trước đây từ khoá CHỈ tìm trong tiêu đề/mô tả/tên phòng/
                // địa chỉ. Các gợi ý ở sheet tìm kiếm ("Có ban công", "Cho nuôi
                // thú cưng", "Gần đại học"…) là nhu cầu về TIỆN ÍCH/NỘI THẤT —
                // không bao giờ xuất hiện trong các cột đó → luôn ra RỖNG khiến
                // người dùng tưởng tìm kiếm hỏng. Nay tìm thêm trong cột
                // `furniture` (mã tiện ích) và `roomType`/`subType` để gợi ý
                // "Chung cư mini"/"Studio" khớp được.
                // BUGFIX: bổ sung `roomSubType` (mã loại phòng canonical, vd
                // STUDIO/CHDV/PHONG_TRO) — trước đây comment nói có tìm nhưng
                // predicate lại THIẾU, khiến gợi ý "Studio"/"Chung cư mini"
                // luôn ra rỗng. Đồng thời quy từ khoá tiếng Việt về mã canonical
                // để "chung cư mini" khớp cột mã (CHDV/STUDIO...).
                java.util.Set<String> keywordTypeCodes =
                        com.stayhub.api.util.RoomTypeCodes.canonicalCodes(c.getKeyword());
                List<Predicate> keywordPredicates = new ArrayList<>();
                keywordPredicates.add(cb.like(cb.lower(root.get("postTitle")), needle));
                keywordPredicates.add(cb.like(cb.lower(root.get("postDescription")), needle));
                keywordPredicates.add(cb.like(cb.lower(room.get("roomName")), needle));
                keywordPredicates.add(cb.like(cb.lower(room.get("address")), needle));
                keywordPredicates.add(cb.like(cb.lower(room.get("addressOld")), needle));
                keywordPredicates.add(cb.like(cb.lower(room.get("description")), needle));
                keywordPredicates.add(cb.like(cb.lower(room.get("furniture")), needle));
                keywordPredicates.add(cb.like(cb.lower(room.get("roomSubType")), needle));
                if (!keywordTypeCodes.isEmpty()) {
                    keywordPredicates.add(cb.upper(room.get("roomSubType"))
                            .in(keywordTypeCodes));
                }
                predicates.add(cb.or(keywordPredicates.toArray(new Predicate[0])));
            }

            // ── Vị trí (bounding box xấp xỉ) ──────────────────────────────────
            if (c.getLat() != null && c.getLng() != null && c.getRadius() != null
                    && c.getRadius() > 0) {
                double latDelta = c.getRadius() / 111.32;
                double lngDelta = c.getRadius()
                        / (111.32 * Math.max(0.01, Math.cos(Math.toRadians(c.getLat()))));
                predicates.add(cb.between(room.get("latitude"),
                        c.getLat() - latDelta, c.getLat() + latDelta));
                predicates.add(cb.between(room.get("longitude"),
                        c.getLng() - lngDelta, c.getLng() + lngDelta));
            }

            // ── Sắp xếp (chỉ áp cho query lấy dữ liệu, không áp cho count) ────
            if (query != null && Long.class != query.getResultType()) {
                applySort(query, cb, root, room, c.getSortBy(), c.getLat(), c.getLng());
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    /**
     * Áp dụng ORDER BY theo lựa chọn của người dùng.
     * Mặc định: mới nhất trước (postCreatedAt DESC).
     *
     * <p>Chuẩn hoá alias để chịu được nhiều cách gọi khác nhau từ client
     * (ví dụ {@code createdAt,desc}, {@code recommend,desc}, {@code newest}).
     * Nhờ vậy frontend cũ lẫn mới đều sắp xếp đúng thay vì rơi vào default.</p>
     */
    private static void applySort(jakarta.persistence.criteria.CriteriaQuery<?> query,
                                  jakarta.persistence.criteria.CriteriaBuilder cb,
                                  jakarta.persistence.criteria.Root<RoomPost> root,
                                  Join<RoomPost, Room> room,
                                  String sortBy,
                                  Double cLat,
                                  Double cLng) {
        String sort = normalizeSort(sortBy);
        switch (sort) {
            case "price_asc" -> query.orderBy(cb.asc(
                    cb.coalesce(root.get("rentingPrice"), room.get("price"))));
            case "price_desc" -> query.orderBy(cb.desc(
                    cb.coalesce(root.get("rentingPrice"), room.get("price"))));
            case "area_asc" -> query.orderBy(cb.asc(room.get("floorArea")));
            case "area_desc" -> query.orderBy(cb.desc(room.get("floorArea")));
            // "distance" (Gần tôi nhất): sắp xếp theo khoảng cách tới vị trí
            // người dùng. Vì ORDER BY không tính được haversine trong JPQL một
            // cách portable, ta sắp xếp theo bình phương khoảng cách xấp xỉ
            // (đủ chính xác cho bán kính nhỏ) khi có toạ độ; nếu không có toạ
            // độ thì rơi về "mới nhất".
            case "distance" -> {
                if (cLat != null && cLng != null) {
                    // Xấp xỉ: ưu tiên phòng gần theo trục vĩ độ trước (delta nhỏ
                    // nhất), sau đó kinh độ. Dùng asc để gần nhất lên đầu.
                    query.orderBy(
                            cb.asc(cb.abs(cb.diff(room.get("latitude"), cLat))),
                            cb.asc(cb.abs(cb.diff(room.get("longitude"), cLng))));
                } else {
                    query.orderBy(cb.desc(root.get("createdAt")));
                }
            }
            case "newest" -> query.orderBy(cb.desc(root.get("createdAt")));
            default -> query.orderBy(cb.desc(root.get("createdAt")));
        }
    }

    /**
     * Chuẩn hoá giá trị {@code sortBy} về tập canonical:
     * {@code newest | price_asc | price_desc | area_asc | area_desc | distance}.
     *
     * <p>Chấp nhận cả các alias cũ/dạng Spring Sort ({@code createdAt,desc},
     * {@code recommend,desc}, {@code price,asc}...) để không phá vỡ client
     * hiện có.</p>
     */
    private static String normalizeSort(String sortBy) {
        if (sortBy == null || sortBy.isBlank()) return "newest";
        String s = sortBy.trim().toLowerCase();

        // Dạng "field,dir" (Spring Sort) → tách lấy field + dir.
        String field = s;
        String dir = "";
        int comma = s.indexOf(',');
        if (comma >= 0) {
            field = s.substring(0, comma).trim();
            dir = s.substring(comma + 1).trim();
        }

        return switch (field) {
            case "price", "rentingprice", "renting_price" ->
                    dir.startsWith("desc") ? "price_desc" : "price_asc";
            case "area", "floorarea", "floor_area" ->
                    dir.startsWith("desc") ? "area_desc" : "area_asc";
            case "distance", "near", "nearby", "gần tôi", "gan toi" -> "distance";
            case "createdat", "created_at", "newest", "recommend", "latest" -> "newest";
            // Đã là canonical sẵn.
            case "price_asc", "price_desc", "area_asc", "area_desc" -> field;
            default -> "newest";
        };
    }

    /**
     * Giữ lại API cũ để không phá vỡ các call-site hiện có.
     *
     * @deprecated dùng {@link #fromCriteria(RoomSearchCriteria)} thay thế.
     */
    @Deprecated
    public static Specification<RoomPost> searchPublicRooms(
            Double minPrice,
            Double maxPrice,
            List<String> roomTypes,
            Integer bedrooms,
            String keyword,
            Double lat,
            Double lng,
            Double radius
    ) {
        return fromCriteria(RoomSearchCriteria.builder()
                .minPrice(minPrice)
                .maxPrice(maxPrice)
                .roomTypes(roomTypes)
                .bedrooms(bedrooms)
                .keyword(keyword)
                .lat(lat)
                .lng(lng)
                .radius(radius)
                .build());
    }
}
