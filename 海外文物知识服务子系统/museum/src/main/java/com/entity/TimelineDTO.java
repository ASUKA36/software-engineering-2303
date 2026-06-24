package com.entity;

import lombok.Data;
import java.io.Serializable;
import java.util.List;

@Data
public class TimelineDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private List<TimelineItem> items;
    private Integer totalAntiques;
    private Integer periodCount;
    private Integer museumCount;

    public List<TimelineItem> getItems() { return items; }
    public void setItems(List<TimelineItem> items) { this.items = items; }
    public Integer getTotalAntiques() { return totalAntiques; }
    public void setTotalAntiques(Integer totalAntiques) { this.totalAntiques = totalAntiques; }
    public Integer getPeriodCount() { return periodCount; }
    public void setPeriodCount(Integer periodCount) { this.periodCount = periodCount; }
    public Integer getMuseumCount() { return museumCount; }
    public void setMuseumCount(Integer museumCount) { this.museumCount = museumCount; }

    @Data
    public static class TimelineItem implements Serializable {
        private String dynasty;
        private String dynastyEn;
        private Integer count;
        private Integer startYear;
        private Integer endYear;
        private List<AntiqueBrief> antiques;

        public String getDynasty() { return dynasty; }
        public void setDynasty(String dynasty) { this.dynasty = dynasty; }
        public String getDynastyEn() { return dynastyEn; }
        public void setDynastyEn(String dynastyEn) { this.dynastyEn = dynastyEn; }
        public Integer getCount() { return count; }
        public void setCount(Integer count) { this.count = count; }
        public Integer getStartYear() { return startYear; }
        public void setStartYear(Integer startYear) { this.startYear = startYear; }
        public Integer getEndYear() { return endYear; }
        public void setEndYear(Integer endYear) { this.endYear = endYear; }
        public List<AntiqueBrief> getAntiques() { return antiques; }
        public void setAntiques(List<AntiqueBrief> antiques) { this.antiques = antiques; }

        public TimelineItem() {}

        public TimelineItem(String dynasty, String dynastyEn, Integer count, Integer startYear, Integer endYear) {
            this.dynasty = dynasty;
            this.dynastyEn = dynastyEn;
            this.count = count;
            this.startYear = startYear;
            this.endYear = endYear;
        }
    }

    @Data
    public static class AntiqueBrief implements Serializable {
        private String objectId;
        private Integer museumId;
        private String title;
        private String museum;
        private String imageUrl;

        public String getObjectId() { return objectId; }
        public void setObjectId(String objectId) { this.objectId = objectId; }
        public Integer getMuseumId() { return museumId; }
        public void setMuseumId(Integer museumId) { this.museumId = museumId; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getMuseum() { return museum; }
        public void setMuseum(String museum) { this.museum = museum; }
        public String getImageUrl() { return imageUrl; }
        public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

        public AntiqueBrief() {}

        public AntiqueBrief(String objectId, Integer museumId, String title, String museum, String imageUrl) {
            this.objectId = objectId;
            this.museumId = museumId;
            this.title = title;
            this.museum = museum;
            this.imageUrl = imageUrl;
        }
    }
}
