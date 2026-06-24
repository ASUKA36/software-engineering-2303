package com.entity;

public class ReviewStrategyConfig {
    private Long id;
    private Integer lowRiskMaxScore;
    private Integer mediumRiskMaxScore;
    private String lowRiskAction;
    private String mediumRiskAction;
    private String highRiskAction;
    private Integer externalImageScore;
    private String remark;

    public ReviewStrategyConfig() {
        // 默认值
        this.lowRiskMaxScore = 20;
        this.mediumRiskMaxScore = 60;
        this.lowRiskAction = "AUTO_APPROVE";
        this.mediumRiskAction = "MANUAL_REVIEW";
        this.highRiskAction = "AUTO_REJECT";
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Integer getLowRiskMaxScore() {
        return lowRiskMaxScore;
    }

    public void setLowRiskMaxScore(Integer lowRiskMaxScore) {
        this.lowRiskMaxScore = lowRiskMaxScore;
    }

    public Integer getMediumRiskMaxScore() {
        return mediumRiskMaxScore;
    }

    public void setMediumRiskMaxScore(Integer mediumRiskMaxScore) {
        this.mediumRiskMaxScore = mediumRiskMaxScore;
    }

    public String getLowRiskAction() {
        return lowRiskAction;
    }

    public void setLowRiskAction(String lowRiskAction) {
        this.lowRiskAction = lowRiskAction;
    }

    public String getMediumRiskAction() {
        return mediumRiskAction;
    }

    public void setMediumRiskAction(String mediumRiskAction) {
        this.mediumRiskAction = mediumRiskAction;
    }

    public String getHighRiskAction() {
        return highRiskAction;
    }

    public void setHighRiskAction(String highRiskAction) {
        this.highRiskAction = highRiskAction;
    }

    public Integer getExternalImageScore() {
        return externalImageScore;
    }

    public void setExternalImageScore(Integer externalImageScore) {
        this.externalImageScore = externalImageScore;
    }

    public String getRemark() {
        return remark;
    }

    public void setRemark(String remark) {
        this.remark = remark;
    }
}