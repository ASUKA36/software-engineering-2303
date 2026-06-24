package com.utils;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class DatabaseChecker {
    public static void main(String[] args) {
        String url = "jdbc:mysql://47.96.152.190:3306/overseas_chinese_artifacts?serverTimezone=UTC&characterEncoding=UTF-8&useSSL=false&allowPublicKeyRetrieval=true";
        String user = "remote_user";
        String password = "!software2303";
        
        try (Connection conn = DriverManager.getConnection(url, user, password);
             Statement stmt = conn.createStatement()) {
            
            ResultSet rs = stmt.executeQuery("SELECT * FROM artifact WHERE dynasty LIKE '%民国%' LIMIT 5");
            java.sql.ResultSetMetaData meta = rs.getMetaData();
            int columnCount = meta.getColumnCount();
            
            System.out.println("=== 民国文物数据 ===");
            while (rs.next()) {
                System.out.println("\n--- 文物记录 ---");
                for (int i = 1; i <= columnCount; i++) {
                    String colName = meta.getColumnName(i);
                    String value = rs.getString(i);
                    if (colName.toLowerCase().contains("url") || colName.toLowerCase().contains("image")) {
                        if (value != null && !value.isEmpty()) {
                            System.out.println(colName + ": " + value);
                        }
                    }
                }
            }
            rs.close();
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}