package com.mapper;

import com.entity.Product;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

@SpringBootTest
@RunWith(SpringRunner.class)
public class ProductMapperTest {
    @Autowired
    private ProductMapper productMapper;

    @Test
    public void findByProductId(){
        // 使用复合主键查询：museumId=1(史密森尼), objectId示例值
        Product product = productMapper.findByProductId(1, "test_object_id");
        System.out.println(product != null ? product.toString() : "未找到文物");
    }
}
