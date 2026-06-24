package com.entity;

import java.io.Serializable;
import java.util.Date;

public class Comment implements Serializable {
    private Long commentId;
    private Long userId;
    private Integer museumId;
    private String objectId;
    private String content;
    private String source;
    private Integer auditMethod;
    private Integer auditStatus;
    private Integer autoAuditStatus;
    private String sensitiveWordsHit;
    private Long auditorId;
    private Integer status;
    private Long deletedBy;
    private String deleteReason;
    private Date createdAt;
    private Date updatedAt;

    public Comment() {
        this.source = "web";
        this.auditMethod = 1;
        this.auditStatus = 0;
        this.status = 1;
    }

    public Long getCommentId() {
        return commentId;
    }

    public void setCommentId(Long commentId) {
        this.commentId = commentId;
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

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

    public Integer getAuditMethod() {
        return auditMethod;
    }

    public void setAuditMethod(Integer auditMethod) {
        this.auditMethod = auditMethod;
    }

    public Integer getAuditStatus() {
        return auditStatus;
    }

    public void setAuditStatus(Integer auditStatus) {
        this.auditStatus = auditStatus;
    }

    public Integer getAutoAuditStatus() {
        return autoAuditStatus;
    }

    public void setAutoAuditStatus(Integer autoAuditStatus) {
        this.autoAuditStatus = autoAuditStatus;
    }

    public String getSensitiveWordsHit() {
        return sensitiveWordsHit;
    }

    public void setSensitiveWordsHit(String sensitiveWordsHit) {
        this.sensitiveWordsHit = sensitiveWordsHit;
    }

    public Long getAuditorId() {
        return auditorId;
    }

    public void setAuditorId(Long auditorId) {
        this.auditorId = auditorId;
    }

    public Integer getStatus() {
        return status;
    }

    public void setStatus(Integer status) {
        this.status = status;
    }

    public Long getDeletedBy() {
        return deletedBy;
    }

    public void setDeletedBy(Long deletedBy) {
        this.deletedBy = deletedBy;
    }

    public String getDeleteReason() {
        return deleteReason;
    }

    public void setDeleteReason(String deleteReason) {
        this.deleteReason = deleteReason;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public Date getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Date updatedAt) {
        this.updatedAt = updatedAt;
    }

    @Override
    public String toString() {
        return "Comment{" +
                "commentId=" + commentId +
                ", userId=" + userId +
                ", museumId=" + museumId +
                ", objectId='" + objectId + '\'' +
                ", content='" + content + '\'' +
                ", source='" + source + '\'' +
                ", auditStatus=" + auditStatus +
                ", status=" + status +
                ", createdAt=" + createdAt +
                '}';
    }
}
