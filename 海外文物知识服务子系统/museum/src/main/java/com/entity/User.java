package com.entity;

import lombok.Data;

import java.util.Date;

@Data
public class User {
    private Long user_id;          // 用户唯一标识ID
    private String username;       // 用户名
    private String user_source;    // 注册来源：web / app
    private String nickname;       // 展示昵称
    private String avatar_url;     // 头像URL
    private Integer sex;           // 性别：0未知1男2女
    private String password;       // 密码（加密存储）
    private String email;          // 邮箱
    private String phone;          // 手机号
    private Date register_time;    // 注册时间
    private Date last_login_at;    // 最近登录时间
    private String last_login_ip;  // 最近登录IP
    private Integer status;        // 1正常0禁用
    private String disabled_reason;// 禁用原因
    private Long disabled_by;      // 禁用操作管理员ID
    private Date disabled_at;      // 禁用时间
    private Date created_at;       // 记录创建时间
    private Date updated_at;       // 信息更新时间
    private Integer canComment;    // 是否允许评论：1允许 0禁止
    private Integer canUpload;     // 是否允许上传：1允许 0禁止

    public User() {
    }

    public Long getUser_id() {
        return user_id;
    }

    public void setUser_id(Long user_id) {
        this.user_id = user_id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getUser_source() {
        return user_source;
    }

    public void setUser_source(String user_source) {
        this.user_source = user_source;
    }

    public String getNickname() {
        return nickname;
    }

    public void setNickname(String nickname) {
        this.nickname = nickname;
    }

    public String getAvatar_url() {
        return avatar_url;
    }

    public void setAvatar_url(String avatar_url) {
        this.avatar_url = avatar_url;
    }

    public Integer getSex() {
        return sex;
    }

    public void setSex(Integer sex) {
        this.sex = sex;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public Date getRegister_time() {
        return register_time;
    }

    public void setRegister_time(Date register_time) {
        this.register_time = register_time;
    }

    public Date getLast_login_at() {
        return last_login_at;
    }

    public void setLast_login_at(Date last_login_at) {
        this.last_login_at = last_login_at;
    }

    public String getLast_login_ip() {
        return last_login_ip;
    }

    public void setLast_login_ip(String last_login_ip) {
        this.last_login_ip = last_login_ip;
    }

    public Integer getStatus() {
        return status;
    }

    public void setStatus(Integer status) {
        this.status = status;
    }

    public String getDisabled_reason() {
        return disabled_reason;
    }

    public void setDisabled_reason(String disabled_reason) {
        this.disabled_reason = disabled_reason;
    }

    public Long getDisabled_by() {
        return disabled_by;
    }

    public void setDisabled_by(Long disabled_by) {
        this.disabled_by = disabled_by;
    }

    public Date getDisabled_at() {
        return disabled_at;
    }

    public void setDisabled_at(Date disabled_at) {
        this.disabled_at = disabled_at;
    }

    public Date getCreated_at() {
        return created_at;
    }

    public void setCreated_at(Date created_at) {
        this.created_at = created_at;
    }

    public Date getUpdated_at() {
        return updated_at;
    }

    public void setUpdated_at(Date updated_at) {
        this.updated_at = updated_at;
    }

    public Integer getCanComment() {
        return canComment;
    }

    public void setCanComment(Integer canComment) {
        this.canComment = canComment;
    }

    public Integer getCanUpload() {
        return canUpload;
    }

    public void setCanUpload(Integer canUpload) {
        this.canUpload = canUpload;
    }

    @Override
    public String toString() {
        return "User{" +
                "user_id=" + user_id +
                ", username='" + username + '\'' +
                ", user_source='" + user_source + '\'' +
                ", nickname='" + nickname + '\'' +
                ", avatar_url='" + avatar_url + '\'' +
                ", sex=" + sex +
                ", password='" + password + '\'' +
                ", email='" + email + '\'' +
                ", phone='" + phone + '\'' +
                ", register_time=" + register_time +
                ", last_login_at=" + last_login_at +
                ", last_login_ip='" + last_login_ip + '\'' +
                ", status=" + status +
                ", disabled_reason='" + disabled_reason + '\'' +
                ", disabled_by=" + disabled_by +
                ", disabled_at=" + disabled_at +
                ", created_at=" + created_at +
                ", updated_at=" + updated_at +
                ", canComment=" + canComment +
                ", canUpload=" + canUpload +
                '}';
    }
}