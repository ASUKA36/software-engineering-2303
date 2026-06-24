package com.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
@Mapper
public interface VisualizationMapper {
    List<Map<String, Object>> getMuseumMapData();
    List<Map<String, Object>> getTypeStat();
}