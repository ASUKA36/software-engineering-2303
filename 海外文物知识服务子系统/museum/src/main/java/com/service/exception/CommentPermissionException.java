package com.service.exception;

public class CommentPermissionException extends ServiceException {

    public CommentPermissionException(String s) {
        super();
        System.out.println(s);
    }
}
