package com.service.exception;

public class DeleteException extends ServiceException{
    public DeleteException(String s){
        super();
        System.out.println(s);
    }
}
