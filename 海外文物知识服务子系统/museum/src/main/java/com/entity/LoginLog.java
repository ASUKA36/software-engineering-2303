package com.entity;

import lombok.Data;
import java.util.Date;

@Data
public class LoginLog {
    private Long id;
    private String userType;
    private Long userId;
    private String username;
    private String result;
    private String ipAddress;
    private String sourceSystem;
    private String userAgent;
    private Date loginTime;

    public LoginLog() {
    }

    public LoginLog(String userType, Long userId, String username, String result,
                    String ipAddress, String sourceSystem, String userAgent, Date loginTime) {
        this.userType = userType;
        this.userId = userId;
        this.username = username;
        this.result = result;
        this.ipAddress = ipAddress;
        this.sourceSystem = sourceSystem;
        this.userAgent = userAgent;
        this.loginTime = loginTime;
    }
}