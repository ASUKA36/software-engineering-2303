package com.service.exception;

public class UserLimitedLoginException extends ServiceException{
    public UserLimitedLoginException() {
    }

    public UserLimitedLoginException(String message) {
        super(message);
    }

    public UserLimitedLoginException(String message, Throwable cause) {
        super(message, cause);
    }

    public UserLimitedLoginException(Throwable cause) {
        super(cause);
    }

    public UserLimitedLoginException(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace) {
        super(message, cause, enableSuppression, writableStackTrace);
    }
}
