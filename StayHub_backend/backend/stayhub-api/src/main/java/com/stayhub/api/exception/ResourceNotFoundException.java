package com.stayhub.api.exception;

public class ResourceNotFoundException extends RuntimeException {

    public ResourceNotFoundException(String message) {
        super(message);
    }

    public ResourceNotFoundException(String resource, Long id) {
        super("Không tìm thấy " + resource + " với ID: " + id);
    }
}
