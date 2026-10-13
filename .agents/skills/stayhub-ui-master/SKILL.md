---
name: stayhub-ui-master
description: >-
  Kỹ năng chuyên biệt để xây dựng giao diện UI/UX cho dự án StayHub,
  đảm bảo thiết kế đẹp nhất, mượt nhất với hiệu ứng Liquid Glass và micro-animations.
---

# 🎨 StayHub UI Master Skill

Kỹ năng này cung cấp các hướng dẫn chi tiết để xây dựng giao diện người dùng (UI) tuyệt đẹp và mượt mà cho dự án StayHub. Khi áp dụng kỹ năng này, bạn **PHẢI** tuân thủ nghiêm ngặt các quy tắc thiết kế sau đây để đạt tiêu chuẩn "đỉnh cao".

## 1. Hệ Thống Màu Sắc & Ánh Sáng (Design System & UI Tokens)
- **Primary Color:** Sky Blue (`#69b1ff`) - Sử dụng làm màu chủ đạo cho các CTA, nhấn mạnh.
- **Surface Color:** Khói nhạt (`#F9FAFB`) - Nền tảng sạch sẽ cho các thẻ và layout.
- **Text Color:** Xanh đen (`#1E293B`) - Đảm bảo độ tương phản và dễ đọc.
- **Elevation & Shadow:** Bóng đổ lan tỏa cực mờ, ám xanh nhạt `0px 8px 24px rgba(105, 177, 255, 0.08)`. Không dùng bóng đổ đen thô kệch.

## 2. Hình Khối & Hiệu Ứng (Shape & Glassmorphism)
- **Buttons:** Nút bấm phải luôn là hình viên thuốc (Pill-shape), border-radius `50px`.
- **Cards & Containers:** Bo góc lớn từ `24px` đến `32px` tạo cảm giác hiện đại, mềm mại.
- **Hiệu ứng Liquid Glass:** 
  - Áp dụng cho các Header, BottomSheet, và Overlay.
  - Sử dụng nền mờ trong suốt (ví dụ: `backdrop-filter: blur(16px)` kết hợp nền trắng hoặc xanh nhạt độ trong suốt 70%).

## 3. Chuyển Động & Tương Tác (Micro-animations)
- **Hover Effects:** Mọi thành phần tương tác (nút, thẻ) đều phải có hiệu ứng khi hover. Ví dụ: scale nhẹ lên `1.02`, nổi bóng đổ rõ hơn, hoặc trượt màu mượt mà.
- **Transitions:** Tất cả các thay đổi trạng thái phải sử dụng transition mượt mà (ví dụ: `transition: all 0.3s cubic-bezier(0.25, 0.8, 0.25, 1)`).
- **Loading & Skeletons:** Tránh để màn hình trống, luôn dùng skeleton loading mượt mà hoặc spinner tinh tế trong lúc chờ dữ liệu.

## 4. Typography
- Sử dụng font chữ hiện đại (như Inter, Roboto, hoặc Outfit).
- Phân cấp rõ ràng giữa Heading (`<h1>` đến `<h6>`) và Body text.
- Line-height thoáng (1.5 đến 1.7 cho đoạn văn) để mang lại cảm giác premium.

## 🛑 Nguyên Tắc Tối Thượng
Giao diện không được phép trông nhàm chán, cơ bản hay "như hàng chợ". Mọi pixel đều phải được chăm chút để tạo cảm giác WOW cho người dùng từ cái nhìn đầu tiên. Hướng tới một sản phẩm đẳng cấp, tinh tế và cực kỳ "mượt".
