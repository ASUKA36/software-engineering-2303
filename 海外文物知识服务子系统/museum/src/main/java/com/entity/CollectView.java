package com.entity;

import java.io.Serializable;
import java.time.LocalDateTime;

public class CollectView implements Serializable {
    private Long favoriteId;
    private Long userId;
    private Integer museumId;
    private String objectId;
    private LocalDateTime createdAt;
    private String username;
    private String objectName;
    private String timePeriod;
    private String imgUrl;

    public Long getFavoriteId() {
        return favoriteId;
    }

    public void setFavoriteId(Long favoriteId) {
        this.favoriteId = favoriteId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Integer getMuseumId() {
        return museumId;
    }

    public void setMuseumId(Integer museumId) {
        this.museumId = museumId;
    }

    public String getObjectId() {
        return objectId;
    }

    public void setObjectId(String objectId) {
        this.objectId = objectId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getObjectName() {
        return objectName;
    }

    public void setObjectName(String objectName) {
        this.objectName = objectName;
    }

    public String getTimePeriod() {
        return timePeriod;
    }

    public void setTimePeriod(String timePeriod) {
        this.timePeriod = timePeriod;
    }

    public String getImgUrl() {
        return imgUrl;
    }

    public void setImgUrl(String imgUrl) {
        this.imgUrl = imgUrl;
    }

    @Override
    public String toString() {
        return "CollectView{" +
                "favoriteId=" + favoriteId +
                ", userId=" + userId +
                ", museumId=" + museumId +
                ", objectId='" + objectId + '\'' +
                ", createdAt=" + createdAt +
                ", username='" + username + '\'' +
                ", objectName='" + objectName + '\'' +
                ", timePeriod='" + timePeriod + '\'' +
                ", imgUrl='" + imgUrl + '\'' +
                '}';
    }
}
