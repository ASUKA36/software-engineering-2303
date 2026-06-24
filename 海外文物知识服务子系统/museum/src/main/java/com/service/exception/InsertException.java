package com.service.exception;

public class InsertException extends ServiceException {

    public InsertException(String s) {
        super(s);
        System.out.println(s);
    }
}
