package com.service.exception;

public class UsernameCompetedException extends  ServiceException{
    public UsernameCompetedException() {
    }

    public UsernameCompetedException(String message) {
        super(message);
    }

    public UsernameCompetedException(String message, Throwable cause) {
        super(message, cause);
    }

    public UsernameCompetedException(Throwable cause) {
        super(cause);
    }

    public UsernameCompetedException(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace) {
        super(message, cause, enableSuppression, writableStackTrace);
    }
}
