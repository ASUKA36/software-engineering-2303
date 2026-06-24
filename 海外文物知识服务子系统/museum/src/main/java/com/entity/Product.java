package com.entity;

import java.io.Serializable;
import java.util.Date;

/**
 * 海外藏中国文物实体类
 * 对应数据库表：artifact
 */
public class Product implements Serializable {
    
    private static final long serialVersionUID = 1L;

    // ============ 核心标识字段 ============
    private String objectId;                        // 文物唯一编号（馆方/EDAN）
    private Integer museumId;                       // 馆别：1史密森尼 2哈佛 3波士顿MFA
    private String accessionNumber;                 // 藏品编号

    // ============ 基础信息字段 ============
    private String title;                           // 文物名称
    private String artist;                          // 作者/制作者
    private String artistProvince;                  // 作者相关省份（推断）
    private String dynasty;                         // 朝代
    private String artistWikidataId;                // Wikidata Q号
    private String artistBirth;                     // 作者生年
    private String artistDeath;                     // 作者卒年
    private String artistBio;                       // 作者简介
    private String artistWikipediaSummary;          // 维基摘要
    private String artistEnrichedAt;                // 作者信息补全时间

    // ============ 年代与类型字段 ============
    private String period;                          // 年代/时期原文
    private Short periodStartYear;                  // 起始年
    private Short periodEndYear;                    // 结束年
    private String type;                            // 文物类型
    private String material;                        // 材质
    private String culture;                         // 文化/地域标签

    // ============ 描述与来源字段 ============
    private String description;                     // 文物介绍
    private String provenance;                      // 流传经历
    private String bibliography;                    // 参考文献
    private String dimensions;                      // 尺寸

    // ============ 博物馆信息字段 ============
    private String museum;                          // 所属博物馆
    private String location;                        // 博物馆所在地
    private String detailUrl;                       // 详情页URL
    private String imageUrl;                        // 图片原始URL
    private String iiifManifestUrl;                 // IIIF manifest（哈佛）
    private String imagePath;                       // 本地相对图片路径
    private String creditLine;                      // 版权/来源说明
    private Date crawlDate;                         // 爬取日期

    /**
     * 无参构造函数
     */
    public Product() {
    }

    /**
     * 有参构造函数
     */
    public Product(Integer museumId, String objectId, String title, String artist) {
        this.museumId = museumId;
        this.objectId = objectId;
        this.title = title;
        this.artist = artist;
    }

    // ========== Getter/Setter 方法 ==========
    public String getObjectId() { return objectId; }
    public void setObjectId(String objectId) { this.objectId = objectId; }

    public Integer getMuseumId() { return museumId; }
    public void setMuseumId(Integer museumId) { this.museumId = museumId; }

    public String getAccessionNumber() { return accessionNumber; }
    public void setAccessionNumber(String accessionNumber) { this.accessionNumber = accessionNumber; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getArtist() { return artist; }
    public void setArtist(String artist) { this.artist = artist; }

    public String getArtistProvince() { return artistProvince; }
    public void setArtistProvince(String artistProvince) { this.artistProvince = artistProvince; }

    public String getDynasty() { return dynasty; }
    public void setDynasty(String dynasty) { this.dynasty = dynasty; }

    public String getArtistWikidataId() { return artistWikidataId; }
    public void setArtistWikidataId(String artistWikidataId) { this.artistWikidataId = artistWikidataId; }

    public String getArtistBirth() { return artistBirth; }
    public void setArtistBirth(String artistBirth) { this.artistBirth = artistBirth; }

    public String getArtistDeath() { return artistDeath; }
    public void setArtistDeath(String artistDeath) { this.artistDeath = artistDeath; }

    public String getArtistBio() { return artistBio; }
    public void setArtistBio(String artistBio) { this.artistBio = artistBio; }

    public String getArtistWikipediaSummary() { return artistWikipediaSummary; }
    public void setArtistWikipediaSummary(String artistWikipediaSummary) { this.artistWikipediaSummary = artistWikipediaSummary; }

    public String getArtistEnrichedAt() { return artistEnrichedAt; }
    public void setArtistEnrichedAt(String artistEnrichedAt) { this.artistEnrichedAt = artistEnrichedAt; }

    public String getPeriod() { return period; }
    public void setPeriod(String period) { this.period = period; }

    public Short getPeriodStartYear() { return periodStartYear; }
    public void setPeriodStartYear(Short periodStartYear) { this.periodStartYear = periodStartYear; }

    public Short getPeriodEndYear() { return periodEndYear; }
    public void setPeriodEndYear(Short periodEndYear) { this.periodEndYear = periodEndYear; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getMaterial() { return material; }
    public void setMaterial(String material) { this.material = material; }

    public String getCulture() { return culture; }
    public void setCulture(String culture) { this.culture = culture; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getProvenance() { return provenance; }
    public void setProvenance(String provenance) { this.provenance = provenance; }

    public String getBibliography() { return bibliography; }
    public void setBibliography(String bibliography) { this.bibliography = bibliography; }

    public String getDimensions() { return dimensions; }
    public void setDimensions(String dimensions) { this.dimensions = dimensions; }

    public String getMuseum() { return museum; }
    public void setMuseum(String museum) { this.museum = museum; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getDetailUrl() { return detailUrl; }
    public void setDetailUrl(String detailUrl) { this.detailUrl = detailUrl; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public String getIiifManifestUrl() { return iiifManifestUrl; }
    public void setIiifManifestUrl(String iiifManifestUrl) { this.iiifManifestUrl = iiifManifestUrl; }

    public String getImagePath() { return imagePath; }
    public void setImagePath(String imagePath) { this.imagePath = imagePath; }

    public String getCreditLine() { return creditLine; }
    public void setCreditLine(String creditLine) { this.creditLine = creditLine; }

    public Date getCrawlDate() { return crawlDate; }
    public void setCrawlDate(Date crawlDate) { this.crawlDate = crawlDate; }

    @Override
    public String toString() {
        return "Product{" +
                "objectId='" + objectId + '\'' +
                ", museumId=" + museumId +
                ", title='" + title + '\'' +
                ", artist='" + artist + '\'' +
                ", dynasty='" + dynasty + '\'' +
                ", museum='" + museum + '\'' +
                '}';
    }
}
