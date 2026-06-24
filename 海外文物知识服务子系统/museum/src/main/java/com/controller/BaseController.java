package com.controller;

import com.service.exception.PasswordNotMatchException;
import com.service.exception.ProductNotFoundException;
import com.service.exception.ServiceException;
import com.service.exception.UserNotFoundException;
import com.util.JsonResult;
import org.springframework.web.bind.annotation.ExceptionHandler;
//基本格式
public class BaseController {
    public static final int OK = 200;

    @ExceptionHandler(ServiceException.class)
    public JsonResult<Void> handleException(Throwable e){
        JsonResult<Void> result = new JsonResult<Void>(e);
        if (e instanceof ServiceException) {
            result.setState(3000);
        } else if(e instanceof UserNotFoundException){
            result.setState(4000);
            result.setMessage("用户不存在或用户id错误");
        } else if (e instanceof PasswordNotMatchException) {
            result.setState(5000);
            result.setMessage("用户密码错误");
        }   else if(e instanceof ProductNotFoundException){
            result.setState(6000);
            result.setMessage("文物不存在");
        }
        return result;

    }
}
