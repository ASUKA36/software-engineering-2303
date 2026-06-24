package com.entity;

import java.io.Serializable;
import java.util.Date;

public class BaseC implements Serializable {
    private Date createdTime;
    private Date modifiedTime;
    public Date getCreatedTime() {
        return createdTime;
    }
    public Date getModifiedTime() {
        return modifiedTime;
    }
    public void setCreatedTime(Date createdTime) {
        this.createdTime = createdTime;
    }
    public void setModifiedTime(Date modifiedTime) {
        this.modifiedTime = modifiedTime;
    }
}
