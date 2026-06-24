package com.controller;

import com.entity.Cart;
import com.service.ICartService;
import com.service.exception.ProductNotFoundException;
import com.util.JsonResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("search")
public class CartController {
    @Autowired
    private ICartService iCartService;
    @RequestMapping("/obscure")//模糊查询结果
    public JsonResult<List<Cart>> findObscure(@RequestBody Map map){//模糊查询
        JsonResult<List<Cart>> result = new JsonResult<>();
        try{
            String str = (String) map.get("keyword");
            result.setData(iCartService.SearchProductObscure(str));
            result.setState(200);
            result.setMessage("查找到以下内容：");
        }catch(ProductNotFoundException e){
            result.setState(4000);
            result.setMessage("未查询到相关文物");
        }
        return result;
    }
    @RequestMapping("/classification")//分类查询
    public JsonResult<List<Cart>> findProducts(@RequestBody Map map){
        JsonResult<List<Cart>> result = new JsonResult<>();
        try{
            String s1 = (String)map.get("v_1");
            String s2 = (String)map.get("v_2");
            String s3 = (String)map.get("v_3");
            String s4 = (String)map.get("v_4");
            String s = null;
            if(s1!=null) s = s1;
            if(s2!=null) s = s2;
            if(s3!=null) s = s3;
            if(s4!=null) s = s4;
            String c = (String)map.get("c");
            result.setData(iCartService.SearchProductByClass(c,s));
            result.setState(200);
            result.setMessage("查找到以下内容：");
        }catch(ProductNotFoundException e){
            result.setState(4000);
            result.setMessage("未查询到相关文物");
        }catch (SecurityException e){
            result.setState(6000);
            result.setMessage("未知查询错误，请联系管理员！");
        }catch (Exception e){
            result.setState(5000);
            result.setMessage("服务器内部错误: " + e.getMessage());
            e.printStackTrace();
        }
        return result;
    }
    @RequestMapping("/sort")//排序查询
    public JsonResult<List<Cart>> find(@RequestParam("way") String way){//字母降序、字母升序、年代升序、年代降序
        JsonResult<List<Cart>> result = new JsonResult<>();
        try{
            result.setState(200);
            result.setData(iCartService.SearchProductBySort(way));
            if(way.equals("wordUp")){
                result.setMessage("按照字母序升序排序：");
            }
            if(way.equals("wordDown")){
                result.setMessage("按照字母序降序排序：");
            }
            if(way.equals("timeUp")){
                result.setMessage("按照时间序升序排序：");
            }
            if(way.equals("timeDown")){
                result.setMessage("按照时间序降序排序：");
            }
            return result;
        }catch (SecurityException e){
            result.setState(6000);
            result.setMessage("未知查询错误，请联系管理员！");
            return result;
        }
    }
    @RequestMapping("/multiFind")
    public JsonResult<List<Cart>> find(@RequestBody Map map){
        JsonResult<List<Cart>> result = new JsonResult<>();
        try{
            String museum = (String) map.get("v_4");
            String cat1 = (String) map.get("v_2");
            String cat2 = (String) map.get("v_1");
            String cat3 = (String) map.get("v_3");
            result.setState(200);
            result.setData(iCartService.SearchProductByMulti(museum,cat1,cat2,cat3));
            result.setMessage("查询到以下文物：");
            return result;
        }catch(ProductNotFoundException e){
            result.setState(4000);
            result.setMessage("未查询到相关文物！");
            return result;
        }

    }

}
