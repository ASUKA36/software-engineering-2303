package com.service.Impl;

import com.mapper.VisualizationMapper;
import com.service.IVisualizationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
@Service
public class VisualizationServiceImpl implements IVisualizationService {

    @Autowired
    private VisualizationMapper visualizationMapper;

    @Override
    public List<Map<String, Object>> getMuseumMapData() {
        return visualizationMapper.getMuseumMapData();
    }

    @Override
    public List<Map<String, Object>> getTypeStat() {
    return visualizationMapper.getTypeStat();
   }
}