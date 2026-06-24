package com.mapper;

import com.entity.LoginLog;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface LoginLogMapper {
    int insertLoginLog(LoginLog loginLog);
}