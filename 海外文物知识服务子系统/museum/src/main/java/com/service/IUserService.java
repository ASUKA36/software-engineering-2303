package com.service;

import com.entity.User;

public interface IUserService {
    User log(Long user_id, String password);
    User loginByUsername(String username, String password);
    User reg(String password, String username, Integer sex, String phone);
    int up(Long user_id, String old_password, String password, String username, String nickname, Integer sex, String email, String phone, String avatar_url);
    int del(Long user_id);
    User getUserById(Long user_id);
}