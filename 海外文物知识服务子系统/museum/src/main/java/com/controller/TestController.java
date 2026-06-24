package com.controller;

import com.entity.Cart;
import com.mapper.CartMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
public class TestController {

    @Autowired
    private CartMapper cartMapper;

    @GetMapping("/api/test/republic")
    public Map<String, Object> testRepublic() {
        List<Cart> result = cartMapper.findByCat2("Republic（民国）");
        Map<String, Object> response = new HashMap<>();
        response.put("count", result.size());
        
        for (int i = 0; i < Math.min(5, result.size()); i++) {
            Cart p = result.get(i);
            Map<String, String> item = new HashMap<>();
            item.put("img_url", p.getImg_url() != null ? p.getImg_url() : "null");
            item.put("image_url", p.getImage_url() != null ? p.getImage_url() : "null");
            item.put("iiif_manifest_url", p.getIiif_manifest_url() != null ? p.getIiif_manifest_url() : "null");
            item.put("image_path", p.getImage_path() != null ? p.getImage_path() : "null");
            item.put("detail_url", p.getDetail_url() != null ? p.getDetail_url() : "null");
            response.put("item_" + i, item);
        }
        
        return response;
    }
}