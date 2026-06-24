package com.entity;

import lombok.Data;
import java.io.Serializable;
import java.util.List;
import java.util.Map;

@Data
public class StatisticsDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private Integer totalAntiques;
    private Integer categoryCount;
    private Integer museumCount;
    private Integer dynastyCount;
    private List<NameValueItem> categoryDistribution;
    private List<NameValueItem> dynastyDistribution;
    private List<NameValueItem> museumRanking;
    private List<NameValueItem> materialDistribution;
    private List<NameValueItem> regionDistribution;
    private List<NameValueItem> yearlyTrend;

    public Integer getTotalAntiques() { return totalAntiques; }
    public void setTotalAntiques(Integer totalAntiques) { this.totalAntiques = totalAntiques; }
    public Integer getCategoryCount() { return categoryCount; }
    public void setCategoryCount(Integer categoryCount) { this.categoryCount = categoryCount; }
    public Integer getMuseumCount() { return museumCount; }
    public void setMuseumCount(Integer museumCount) { this.museumCount = museumCount; }
    public Integer getDynastyCount() { return dynastyCount; }
    public void setDynastyCount(Integer dynastyCount) { this.dynastyCount = dynastyCount; }
    public List<NameValueItem> getCategoryDistribution() { return categoryDistribution; }
    public void setCategoryDistribution(List<NameValueItem> categoryDistribution) { this.categoryDistribution = categoryDistribution; }
    public List<NameValueItem> getDynastyDistribution() { return dynastyDistribution; }
    public void setDynastyDistribution(List<NameValueItem> dynastyDistribution) { this.dynastyDistribution = dynastyDistribution; }
    public List<NameValueItem> getMuseumRanking() { return museumRanking; }
    public void setMuseumRanking(List<NameValueItem> museumRanking) { this.museumRanking = museumRanking; }
    public List<NameValueItem> getMaterialDistribution() { return materialDistribution; }
    public void setMaterialDistribution(List<NameValueItem> materialDistribution) { this.materialDistribution = materialDistribution; }
    public List<NameValueItem> getRegionDistribution() { return regionDistribution; }
    public void setRegionDistribution(List<NameValueItem> regionDistribution) { this.regionDistribution = regionDistribution; }
    public List<NameValueItem> getYearlyTrend() { return yearlyTrend; }
    public void setYearlyTrend(List<NameValueItem> yearlyTrend) { this.yearlyTrend = yearlyTrend; }

    @Data
    public static class NameValueItem implements Serializable {
        private String name;
        private Integer value;

        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public Integer getValue() { return value; }
        public void setValue(Integer value) { this.value = value; }

        public NameValueItem() {}

        public NameValueItem(String name, Integer value) {
            this.name = name;
            this.value = value;
        }
    }
}
