package com.service.Impl;

import com.mapper.UserMapper;
import com.entity.User;
import com.service.IUserService;
import com.service.exception.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.DigestUtils;

import java.util.UUID;

@Service
public class UserServiceImpl implements IUserService {
    @Autowired
    private UserMapper userMapper;

    /**
     * 加密盐值：用于增强密码安全性，防止彩虹表攻击
     * 说明：当前使用固定盐值"museum"，实际生产环境建议为每个用户生成独立随机盐值
     */
    private String salt = "museum";

    /**
     * 密码加密方法（MD5 + 盐值 + 三重加密）
     * 说明：加密在应用层实现，与数据库无关，数据库仅存储加密后的密文
     *       MD5为单向哈希算法，无法逆向解密
     * 
     * 加密流程：
     * 1. 拼接格式：salt + password + salt
     * 2. 使用MD5算法加密
     * 3. 循环加密3次增强安全性
     * 4. 转换为大写十六进制字符串返回
     * 
     * @param password 用户输入的明文密码
     * @param salt     加密盐值
     * @return 加密后的密码（32位大写十六进制字符串）
     */
    private String getMd5Password(String password, String salt) {
        for (int i = 0; i < 3; i++) {
            password = DigestUtils.md5DigestAsHex((salt + password + salt).getBytes()).toUpperCase();
        }
        return password;
    }

    @Override
    public User log(Long user_id, String password){
        User result = userMapper.findByUser_id(user_id);
        if(result == null) {
            throw new UserNotFoundException("用户不存在");
        }
        String md5Password = getMd5Password(password, salt);
        User result2 = userMapper.findByUser_password(user_id, md5Password);
        if(result2 == null){
            throw new PasswordNotMatchException("用户密码错误");
        }
        if(result2.getStatus() == 1){
            return result2;
        } else {
            throw new UserLimitedLoginException("您的账号已被禁用");
        }
    }

    @Override
    public User loginByUsername(String username, String password){
        User result = userMapper.findByUsername(username);
        if(result == null) {
            throw new UserNotFoundException("用户不存在");
        }
        String md5Password = getMd5Password(password, salt);
        User result2 = userMapper.findByUser_password(result.getUser_id(), md5Password);
        if(result2 == null){
            throw new PasswordNotMatchException("密码错误");
        }
        if(result2.getStatus() == 1){
            return result2;
        } else {
            throw new UserLimitedLoginException("您的账号已被禁用");
        }
    }

    @Override
    public User reg(String password, String username, Integer sex, String phone){
        User existingUser = userMapper.findByUsername(username);
        if(existingUser != null) {
            throw new userRepetitionException("用户名重复！");
        }

        User user = new User();
        String md5Password = getMd5Password(password, salt);
        user.setPassword(md5Password);
        user.setUsername(username);
        user.setSex(sex);
        user.setPhone(phone);
        user.setUser_source("web");
        user.setStatus(1);
        user.setCanComment(1);
        user.setCanUpload(1);

        int row = userMapper.insert_user(user);
        if(row == 1) {
            return userMapper.findByUsername(username);
        } else {
            throw new ServiceException("添加用户数据出现未知错误，请联系系统管理员");
        }
    }

    @Override
    public int up(Long user_id, String old_password, String password, String username, String nickname, Integer sex, String email, String phone, String avatar_url) {
        User existingUser = userMapper.findByUser_id(user_id);
        if(existingUser == null) {
            throw new UserNotFoundException("用户不存在");
        }

        String md5OldPassword = getMd5Password(old_password, salt);
        if(!md5OldPassword.equals(existingUser.getPassword())) {
            throw new PasswordNotMatchException("原密码输入错误");
        }

        User usernameCheck = userMapper.findByUsername(username);
        if(usernameCheck != null && !usernameCheck.getUser_id().equals(user_id)) {
            throw new UsernameCompetedException("用户名已被使用");
        }

        User user = new User();
        user.setUser_id(user_id);
        user.setPassword(password != null && !password.isEmpty() ? getMd5Password(password, salt) : existingUser.getPassword());
        user.setUsername(username);
        user.setNickname(nickname != null && !nickname.isEmpty() ? nickname : existingUser.getNickname());
        user.setSex(sex != null ? sex : existingUser.getSex());
        user.setEmail(email != null && !email.isEmpty() ? email : existingUser.getEmail());
        user.setPhone(phone != null && !phone.isEmpty() ? phone : existingUser.getPhone());
        user.setAvatar_url(avatar_url != null && !avatar_url.isEmpty() ? avatar_url : existingUser.getAvatar_url());

        int row = userMapper.update(user);
        if(row != 0) {
            return row;
        } else {
            throw new ServiceException("更新失败");
        }
    }

    @Override
    public int del(Long user_id){
        User user = userMapper.findByUser_id(user_id);
        if(user == null) {
            throw new UserNotFoundException("用户不存在");
        }
        int row = userMapper.delete(user);
        if(row != 0){
            return row;
        } else {
            throw new ServiceException("删除失败");
        }
    }

    @Override
    public User getUserById(Long user_id) {
        return userMapper.findByUser_id(user_id);
    }
}