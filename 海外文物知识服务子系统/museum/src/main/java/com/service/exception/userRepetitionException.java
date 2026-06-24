package com.service.exception;

public class userRepetitionException extends ServiceException{
    public userRepetitionException() {
    }

    public userRepetitionException(String message) {
        super(message);
    }

    public userRepetitionException(String message, Throwable cause) {
        super(message, cause);
    }

    public userRepetitionException(Throwable cause) {
        super(cause);
    }

    public userRepetitionException(String message, Throwable cause, boolean enableSuppression, boolean writableStackTrace) {
        super(message, cause, enableSuppression, writableStackTrace);
    }
}
