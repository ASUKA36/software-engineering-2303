package com.controller;

import com.service.IVisualizationService;
import com.util.JsonResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;


@RestController

@RequestMapping("visualization")
public class VisualizationController extends BaseController {

    @Autowired
    private IVisualizationService visualizationService;

    @RequestMapping("/museum-map")
    public JsonResult<List<Map<String, Object>>> getMuseumMapData() {
        JsonResult<List<Map<String, Object>>> result = new JsonResult<>();

        try {
            result.setData(visualizationService.getMuseumMapData());
            result.setState(200);
            result.setMessage("获取文物地理分布数据成功");
        } catch (Exception e) {
            result.setState(6000);
            result.setMessage("获取文物地理分布数据失败：" + e.getMessage());
        }

        return result;
    }

    
@RequestMapping("/type-stat")
public JsonResult<List<Map<String, Object>>> getTypeStat() {
    JsonResult<List<Map<String, Object>>> result = new JsonResult<>();

    try {
        result.setData(visualizationService.getTypeStat());
        result.setState(200);
        result.setMessage("获取文物类型统计成功");
    } catch (Exception e) {
        result.setState(6000);
        result.setMessage("获取文物类型统计失败：" + e.getMessage());
    }

    return result;
}

}
