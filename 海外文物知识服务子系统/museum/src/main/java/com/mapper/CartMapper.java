package com.mapper;

import com.entity.Cart;

import java.math.BigInteger;
import java.util.List;

public interface CartMapper {
    List<Cart> findByMuseum(String museum);//通过博物馆搜索
    List<Cart> findByCat1(String cat1);//通过材质搜索
    List<Cart> findByCat2(String cat2);//通过年代查询
    List<Cart> findByCat3(String cat3);//通过分类搜索
    List<Cart> sortByNameUp();//字母序升序
    List<Cart> sortByNameDown();//字母序降序
    List<Cart> sortByTimeUp();//朝代升序
    List<Cart> sortByTimeDown();//朝代降序
    List<Cart> findByMulti(String museum, String cat1, String cat2, String cat3);//多字段查询
    List<Cart> obscureSearch(String str);//模糊查询
    Cart findByMuseum1(String museum, BigInteger id, int start, int end);
    Cart findBymakername1(String makers_name,BigInteger id,int start,int end);
    Cart findBytime1(String cat2,BigInteger id,int start,int end);
    Cart findBygeography(String geography,BigInteger id,int start,int end);
    Cart findone(BigInteger id,int start,int end);

}
