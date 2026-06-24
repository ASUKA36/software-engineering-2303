package com.service;

import com.entity.Cart;

import java.math.BigInteger;
import java.util.List;

public interface ICartService {
//    List<Cart> findByMuseum(String museum);//通过博物馆搜索
//    List<Cart> findByCat1(String cat1);//通过材质搜索
//    List<Cart> findByCat2(String cat2);//通过年代查询
//    List<Cart> findByCat3(String cat3);//通过分类搜索
    List<Cart> SearchProductByClass(String x,String y);//分类搜索
    List<Cart> SearchProductBySort(String x);//排序搜索
    List<Cart> SearchProductByMulti(String museum,String cat1,String cat2,String cat3);
    List<Cart> SearchProductObscure(String str);
    List<Cart> SearchCommentView(String museum, String cat2, String makers_name, String geography, BigInteger id);//相关功能推荐
}
