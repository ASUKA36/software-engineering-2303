package com.controller;

import com.entity.StatisticsDTO;
import com.entity.TimelineDTO;
import com.service.IProductService;
import com.util.JsonResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("dataviz")
public class DataVizController extends BaseController {

    @Autowired
    private IProductService productService;

    @GetMapping("/statistics")
    public JsonResult<StatisticsDTO> getStatistics() {
        JsonResult<StatisticsDTO> result = new JsonResult<>();
        try {
            StatisticsDTO data = productService.getStatistics();
            result.setData(data);
            result.setState(200);
            result.setMessage("获取统计数据成功");
        } catch (Exception e) {
            result.setState(6000);
            result.setMessage("获取统计数据失败：" + e.getMessage());
            e.printStackTrace();
        }
        return result;
    }

    @GetMapping("/timeline")
    public JsonResult<TimelineDTO> getTimeline() {
        JsonResult<TimelineDTO> result = new JsonResult<>();
        try {
            TimelineDTO data = productService.getTimeline();
            result.setData(data);
            result.setState(200);
            result.setMessage("获取时间轴数据成功");
        } catch (Exception e) {
            result.setState(6000);
            result.setMessage("获取时间轴数据失败：" + e.getMessage());
            e.printStackTrace();
        }
        return result;
    }
}
