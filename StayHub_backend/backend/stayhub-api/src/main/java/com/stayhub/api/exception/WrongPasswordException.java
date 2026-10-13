package com.stayhub.api.exception;

public class WrongPasswordException extends RuntimeException {
    private final String name;
    private final String avatar;

    public WrongPasswordException(String message, String name, String avatar) {
        super(message);
        this.name = name;
        this.avatar = avatar;
    }

    public String getName() {
        return name;
    }

    public String getAvatar() {
        return avatar;
    }
}
