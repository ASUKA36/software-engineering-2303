package com.mapper;

import com.entity.User;

public interface UserMapper {
    User findByUser_id(Long user_id);
    User findByUsername(String username);
    User findByUser_password(Long user_id, String password);
    int insert_user(User user);
    int update(User user);
    int delete(User user);
    int updateLastLogin(Long user_id, String ip);
}