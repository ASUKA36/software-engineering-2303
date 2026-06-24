package com.entity;

import java.io.Serializable;
import java.time.LocalDateTime;

public class Collect implements Serializable {
    private Long favoriteId;
    private Long userId;
    private Integer museumId;
    private String objectId;
    private LocalDateTime createdAt;

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

    @Override
    public String toString() {
        return "Collect{" +
                "favoriteId=" + favoriteId +
                ", userId=" + userId +
                ", museumId=" + museumId +
                ", objectId='" + objectId + '\'' +
                ", createdAt=" + createdAt +
                '}';
    }
}
