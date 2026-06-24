package com.entity;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.math.BigInteger;
import java.util.Date;

@Data
@JsonInclude(JsonInclude.Include.NON_NULL)
public class Cart {
    @JsonProperty("id")
    private BigInteger id;
    @JsonProperty("object_name")
    private String object_name;
    @JsonProperty("title")
    private String title;
    @JsonProperty("dynasty")
    private String dynasty;
    @JsonProperty("period")
    private String period;
    @JsonProperty("period_start_year")
    private Short period_start_year;
    @JsonProperty("type")
    private String type;
    @JsonProperty("material")
    private String material;
    @JsonProperty("museum")
    private String museum;
    @JsonProperty("location")
    private String location;
    @JsonProperty("culture")
    private String culture;
    @JsonProperty("artist")
    private String artist;
    @JsonProperty("description")
    private String description;
    @JsonProperty("dimensions")
    private String dimensions;
    @JsonProperty("credit_line")
    private String credit_line;
    @JsonProperty("accession_number")
    private String accession_number;
    @JsonProperty("image_url")
    private String image_url;
    @JsonProperty("detail_url")
    private String detail_url;
    @JsonProperty("image_path")
    private String image_path;
    @JsonProperty("iiif_manifest_url")
    private String iiif_manifest_url;
    @JsonProperty("crawl_date")
    private Date crawl_date;
    @JsonProperty("provenance")
    private String provenance;
    @JsonProperty("bibliography")
    private String bibliography;
    @JsonProperty("object_id")
    private String object_id;
    @JsonProperty("museum_id")
    private Integer museum_id;
    @JsonProperty("artist_wikidata_id")
    private String artist_wikidata_id;
    @JsonProperty("artist_birth")
    private String artist_birth;
    @JsonProperty("artist_death")
    private String artist_death;
    @JsonProperty("artist_bio")
    private String artist_bio;
    @JsonProperty("artist_wikipedia_summary")
    private String artist_wikipedia_summary;
    @JsonProperty("artist_enriched_at")
    private String artist_enriched_at;
    @JsonProperty("period_end_year")
    private Short period_end_year;
    @JsonProperty("artist_province")
    private String artist_province;
    
    // 向后兼容的字段
    @JsonProperty("cat1")
    private String cat1;
    @JsonProperty("cat2")
    private String cat2;
    @JsonProperty("cat3")
    private String cat3;
    @JsonProperty("makers_name")
    private String makers_name;
    @JsonProperty("img_url")
    private String img_url;
    
    public Cart() {
    }

    // 手动添加的 getter/setter 方法
    public BigInteger getId() {
        return this.id;
    }
    
    public void setId(BigInteger id) {
        this.id = id;
    }
    
    public String getImg_url() {
        return this.img_url;
    }
    
    public void setImg_url(String img_url) {
        this.img_url = img_url;
    }
    
    public String getImage_url() {
        return this.image_url;
    }
    
    public void setImage_url(String image_url) {
        this.image_url = image_url;
    }
    
    public String getIiif_manifest_url() {
        return this.iiif_manifest_url;
    }
    
    public void setIiif_manifest_url(String iiif_manifest_url) {
        this.iiif_manifest_url = iiif_manifest_url;
    }
    
    public String getImage_path() {
        return this.image_path;
    }
    
    public void setImage_path(String image_path) {
        this.image_path = image_path;
    }
    
    public String getDetail_url() {
        return this.detail_url;
    }
    
    public void setDetail_url(String detail_url) {
        this.detail_url = detail_url;
    }
    
    public String getMakers_name() {
        return this.makers_name;
    }
    
    public void setMakers_name(String makers_name) {
        this.makers_name = makers_name;
    }

    @Override
    public String toString() {
        return "Cart{" +
                "id=" + id +
                ", title='" + title + '\'' +
                ", dynasty='" + dynasty + '\'' +
                ", museum='" + museum + '\'' +
                '}' + "\n";
    }
}
