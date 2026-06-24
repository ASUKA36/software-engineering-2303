package com.entity;

import java.io.Serializable;
import java.util.Date;

public class BaseEntity implements Serializable {
    private String createdUser;
    private Date createdTime;
    private String modifiedUser;
    private Date modifiedTime;
    public void setCreatedUser(String s){
        this.createdUser=s;
    }
    public void setCreatedTime(Date now){
        this.createdTime=now;
    }
    public void setModifiedUser(String s){
        this.createdUser=s;
    }
    public void setModifiedTime(Date now){
        this.modifiedTime=now;
    }

    public String getCreatedUser() {
        return createdUser;
    }

    public Date getCreatedTime() {
        return createdTime;
    }

    public String getModifiedUser() {
        return modifiedUser;
    }

    public Date getModifiedTime() {
        return modifiedTime;
    }
}
