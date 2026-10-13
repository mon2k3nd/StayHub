package com.stayhub.api.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;
import java.util.stream.Collectors;

@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = ex.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.toMap(
                        FieldError::getField,
                        f -> f.getDefaultMessage() != null ? f.getDefaultMessage() : "Giá trị không hợp lệ",
                        (e1, e2) -> e1
                ));
        // BUGFIX: trước đây gọi errors.values().iterator().next() trực tiếp.
        // Nếu vi phạm là ràng buộc cấp class (không gắn field) thì getFieldErrors()
        // rỗng → iterator().next() ném NoSuchElementException → 500 thay vì 400.
        // Nay fallback an toàn về thông báo chung.
        String firstMessage = errors.isEmpty()
                ? "Dữ liệu gửi lên không hợp lệ"
                : errors.values().iterator().next();
        return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "message", firstMessage,
                "errors", errors
        ));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> handleResponseStatus(ResponseStatusException ex) {
        String message = ex.getReason() != null ? ex.getReason() : "Có lỗi xảy ra";
        return ResponseEntity.status(ex.getStatusCode()).body(Map.of(
                "success", false,
                "message", message
        ));
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                "success", false,
                "message", ex.getMessage()
        ));
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, Object>> handleAccessDenied(AccessDeniedException ex) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                "success", false,
                "message", ex.getMessage() != null ? ex.getMessage() : "Bạn không có quyền thực hiện hành động này"
        ));
    }

    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, Object>> handleDataIntegrityViolation(org.springframework.dao.DataIntegrityViolationException ex) {
        String message = "Dữ liệu không hợp lệ hoặc đã tồn tại trên hệ thống.";
        if (ex.getMessage() != null && ex.getMessage().contains("duplicate key value violates unique constraint")) {
            if (ex.getMessage().contains("branch_code")) {
                message = "Mã dãy trọ đã tồn tại. Vui lòng nhập mã khác!";
            } else if (ex.getMessage().contains("email")) {
                message = "Email này đã được sử dụng.";
            } else if (ex.getMessage().contains("phone")) {
                message = "Số điện thoại này đã được sử dụng.";
            }
        }
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                "success", false,
                "message", message
        ));
    }

    @ExceptionHandler({IllegalStateException.class, IllegalArgumentException.class, BadRequestException.class})
    public ResponseEntity<Map<String, Object>> handleIllegalState(RuntimeException ex) {
        log.warn("Lỗi nghiệp vụ (Business logic error): {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                "success", false,
                "message", ex.getMessage() != null ? ex.getMessage() : "Giá trị hoặc trạng thái không hợp lệ"
        ));
    }

    @ExceptionHandler(WrongPasswordException.class)
    public ResponseEntity<Map<String, Object>> handleWrongPassword(WrongPasswordException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of(
                "success", false,
                "message", ex.getMessage(),
                "name", ex.getName() != null ? ex.getName() : "",
                "avatar", ex.getAvatar() != null ? ex.getAvatar() : ""
        ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleGeneral(Exception ex) {
        log.error("Lỗi không mong đợi", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "success", false,
                "message", "Lỗi: " + ex.getMessage()
        ));
    }
}
