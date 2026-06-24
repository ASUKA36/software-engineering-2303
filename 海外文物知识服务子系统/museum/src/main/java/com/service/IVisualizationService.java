package com.service;

import java.util.List;
import java.util.Map;

public interface IVisualizationService {

    List<Map<String, Object>> getMuseumMapData();

    List<Map<String, Object>> getTypeStat();
}