package com.mapper;

import com.entity.Cart;
import com.service.ICartService;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import java.util.List;

@SpringBootTest
@RunWith(SpringRunner.class)
public class CartMapperTest {
    @Autowired
    private CartMapper cartMapper;

    @Autowired
    private ICartService iCartService;

    @Autowired
    private FindImageMapper findImageMapper;
    @Test
    public void findByMuseum(){
        List<Cart> result;
        result = cartMapper.findByMuseum("Freersackler");
        System.out.println(result.toString());

    }
    @Test
    public void findByCat1(){
        List<Cart> result;
        result = cartMapper.findByCat1("Porcelain");
        System.out.println(result.toString());

    }
    @Test
    public void SortByTimeUp(){
        List<Cart> result;
        result = iCartService.SearchProductBySort("wordUp");
        System.out.println(result.toString());
    }
    @Test
    public void Multi(){
        List<Cart> result;
        result = iCartService.SearchProductByMulti("Freersackler","glaze","Modern period","Painting");
        System.out.println(result.toString());
    }

    @Test
    public void obscure(){
        List<Cart> result;
        result = iCartService.SearchProductObscure("ink");
        System.out.println(result.toString());
    }

    @Test
    public void classification(){
        List<Cart> result;
        result = iCartService.SearchProductByClass("museum","Freersackler");
//        result = cartMapper.findByMuseum("Freersackler");
        for(int i=0;i<result.size();i++){
            Cart p = result.get(i);
            System.out.println(p.getId()+p.getImg_url());
        }
    }

    @Test
    public void findImage(){
        System.out.println(findImageMapper.findImage("069d3bb0_562"));
    }


}
