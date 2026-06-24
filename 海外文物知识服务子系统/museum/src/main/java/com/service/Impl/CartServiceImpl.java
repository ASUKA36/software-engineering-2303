package com.service.Impl;

import com.entity.Cart;
import com.entity.Product;
import com.mapper.CartMapper;
import com.mapper.FindImageMapper;
import com.mapper.ProductMapper;
import com.service.ICartService;
import com.service.exception.ProductNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

@Service
public class CartServiceImpl implements ICartService {
    @Autowired
    private CartMapper cartMapper;
    @Autowired
    private ProductMapper productMapper;

    @Autowired
    private FindImageMapper findImageMapper  ;
//分类查询
    @Override
    public List<Cart> SearchProductByClass(String x,String y) {//博物馆、材质、朝代、分类输入查询
        List<Cart> result;
        if(x.equals("museum")){
            result = cartMapper.findByMuseum(y);
            if(result==null){
                throw new ProductNotFoundException("查询结果为空");
            }
            for (int i=0;i<result.size();i++) {//只选取第一张图片作为显示
                Cart p = result.get(i);
                if(p.getImg_url()==null) continue;
                String[] address =p.getImg_url().split(",");
                p.setImg_url(address[0]);
                result.set(i,p);
            }
            for(int j=0;j<result.size();j++){//访问对应的图片外网
                Cart p = result.get(j);
                if(p.getImg_url()==null) continue;
                // p.setImg_url(findImageMapper.findImage(p.getImg_url()));
                result.set(j,p);
            }
            return result;
        }
        if(x.equals("mart")){
            result = cartMapper.findByCat1(y);
            if(result==null){
                throw new ProductNotFoundException("查询结果为空");
            }
            for (int i=0;i<result.size();i++) {//只选取第一张图片作为显示
                Cart p = result.get(i);
                if(p.getImg_url()==null) continue;
                 String[] address = p.getImg_url().split(",");
                p.setImg_url(address[0]);
                result.set(i,p);
            }
            for(int j=0;j<result.size();j++){//访问对应的图片外网
                Cart p = result.get(j);
                if(p.getImg_url()==null) continue;
                // p.setImg_url(findImageMapper.findImage(p.getImg_url()));
                result.set(j,p);
            }
            return result;
        }
        if(x.equals("dynasty")){
            result = cartMapper.findByCat2(y);
            if(result==null){
                throw new ProductNotFoundException("查询结果为空");
            }
            for (int i=0;i<result.size();i++) {//只选取第一张图片作为显示
                Cart p = result.get(i);
                if(p.getImg_url()==null) continue;
                String[] address = p.getImg_url().split(",");
                p.setImg_url(address[0]);
//                System.out.println(p.getId()+p.getImg_url());
                result.set(i,p);
            }
            for(int j=0;j<result.size();j++){//访问对应的图片外网
                Cart p = result.get(j);
                if(p.getImg_url()==null) continue;
                // p.setImg_url(findImageMapper.findImage(p.getImg_url()));
                result.set(j,p);
            }
            return result;
        }
        if(x.equals("use")){
            result = cartMapper.findByCat3(y);
            if(result==null){
                throw new ProductNotFoundException("查询结果为空");
            }
            for (int i=0;i<result.size();i++) {//只选取第一张图片作为显示
                Cart p = result.get(i);
                if(p.getImg_url()==null) continue;
                 String[] address = p.getImg_url().split(",");
                p.setImg_url(address[0]);
                result.set(i,p);
            }
            for(int j=0;j<result.size();j++){//访问对应的图片外网
                Cart p = result.get(j);
                if(p.getImg_url()==null) continue;
                // p.setImg_url(findImageMapper.findImage(p.getImg_url()));
                result.set(j,p);
            }
            return result;
        }
        else{
            throw new SecurityException("查询错误");
        }
    }
//排序查询
    @Override
    public List<Cart> SearchProductBySort(String x) {
        List<Cart> result ;
        if(x.equals("wordUp")){
            result = cartMapper.sortByNameUp();
            for (int i=0;i<result.size();i++) {//只选取第一张图片作为显示
                Cart p = result.get(i);
                if(p.getImg_url()==null) continue;
                 String[] address = p.getImg_url().split(",");
                p.setImg_url(address[0]);
                result.set(i,p);
            }
            return result;
        }
        if(x.equals("wordDown")){
            result = cartMapper.sortByNameDown();
            for (int i=0;i<result.size();i++) {//只选取第一张图片作为显示
                Cart p = result.get(i);
                 String[] address = p.getImg_url().split(",");
                p.setImg_url(address[0]);
                result.set(i,p);
            }
            return result;
        }
        if(x.equals("timeUp")){
            result = cartMapper.sortByTimeUp();
            for (int i=0;i<result.size();i++) {//只选取第一张图片作为显示
                Cart p = result.get(i);
                 String[] address = p.getImg_url().split(",");
                p.setImg_url(address[0]);
                result.set(i,p);
            }
            return result;
        }
        if(x.equals("timeDown")){
            result = cartMapper.sortByTimeDown();
            for (int i=0;i<result.size();i++) {//只选取第一张图片作为显示
                Cart p = result.get(i);
                 String[] address = p.getImg_url().split(",");
                p.setImg_url(address[0]);
                result.set(i,p);
            }
            return result;
        }
        else{
            throw new SecurityException("查询错误");
        }
    }
//多字段查询
    @Override
    public List<Cart> SearchProductByMulti(String museum, String cat1, String cat2, String cat3) {
        List<Cart> result;
        result = cartMapper.findByMulti(museum,cat1,cat2,cat3);
        if(result!=null){
            for (int i=0;i<result.size();i++) {//只选取第一张图片作为显示
                Cart p = result.get(i);
                if(p.getImg_url()==null) continue;
                String [] address = p.getImg_url().split(",");
                p.setImg_url(address[0]);
                result.set(i,p);
            }
            for(int j=0;j<result.size();j++){//访问对应的图片外网
                Cart p = result.get(j);
                if(p.getImg_url()==null) continue;
                // p.setImg_url(findImageMapper.findImage(p.getImg_url()));
                result.set(j,p);
            }
            return result;
        }
        else{
            throw new ProductNotFoundException("未查询到相关文物！");
        }
    }

    @Override
    public List<Cart> SearchProductObscure(String str) {
        List<Cart> result;
        result = cartMapper.obscureSearch(str);
        if(result!=null){
            for (int i=0;i<result.size();i++) {//只选取第一张图片作为显示
                Cart p = result.get(i);
                if(p.getImg_url()==null) continue;
                 String[] address = p.getImg_url().split(",");
                p.setImg_url(address[0]);
                result.set(i,p);
            }
            for(int j=0;j<result.size();j++){//访问对应的图片外网
                Cart p = result.get(j);
                if(p.getImg_url()==null) continue;
                // p.setImg_url(findImageMapper.findImage(p.getImg_url()));
                result.set(j,p);
            }
            return result;
        }
        else{
            throw new ProductNotFoundException("未查询到相关文物！");
        }
    }
    ///相关推荐查询
        @Override
        public List<Cart> SearchCommentView(String museum, String cat2, String makers_name, String geography, BigInteger id){
            List<Cart> commentView=new ArrayList<Cart>();
            int n=4;
            Cart cart=new Cart();
            List<BigInteger> a1=new ArrayList<BigInteger>();
            cart=cartMapper.findBygeography(geography,id,0,1);
            if(cart != null){
                if(cart.getImg_url()!=null)
                {
                    String[] address = cart.getImg_url().split(",");
                    cart.setImg_url(address[0]);
                    // cart.setImg_url(findImageMapper.findImage(cart.getImg_url()));
                }
                commentView.add(cart);
                a1.add(cart.getId());
                n--;
            }
            cart=cartMapper.findBytime1(cat2,id,0,1);
            if(cart!=null){
                for(int i=0;i<a1.size();i++){
                    if(cart==null)
                        break;
                    if(cart.getId()==a1.get(i)){
                        cart=cartMapper.findBygeography(cat2,id,Integer.valueOf(a1.get(i).toString()),1);
                        i=-1;
                    }
                }
                if(cart!=null){
                    if(cart.getImg_url()!=null)
                    {
                        String[] address = cart.getImg_url().split(",");
                        cart.setImg_url(address[0]);
                        // cart.setImg_url(findImageMapper.findImage(cart.getImg_url()));
                    }
                    commentView.add(cart);
                    a1.add(cart.getId());
                    n--;}
            }
            cart=cartMapper.findBymakername1(makers_name,id,0,1);
            if(cart!=null){
                for(int i=0;i<a1.size();i++){
                    if(cart==null)
                        break;
                    if(cart.getId()==a1.get(i)){
                        cart=cartMapper.findBymakername1(makers_name,id,Integer.valueOf(a1.get(i).toString()),1);
                        i=-1;
                    }
                }
                if(cart!=null){
                    if(cart.getImg_url()!=null)
                    {
                        String[] address = cart.getImg_url().split(",");
                        cart.setImg_url(address[0]);
                        // cart.setImg_url(findImageMapper.findImage(cart.getImg_url()));
                    }
                    commentView.add(cart);
                    a1.add(cart.getId());
                    n--;
                }
            }
            while(n!=0){
                cart=cartMapper.findByMuseum1(museum,id,0,1);
                if(cart!=null){
                    for(int i=0;i<a1.size();i++){
                        if(cart==null)
                            break;
                        if(cart.getId()==a1.get(i)){
                            cart=cartMapper.findByMuseum1(museum,id,Integer.valueOf(a1.get(i).toString()),1);
                            i=-1;
                        }
                    }}
                if(cart==null){
                    break;
                }
                if(cart.getImg_url()!=null)
                {
                    String[] address = cart.getImg_url().split(",");
                    cart.setImg_url(address[0]);
                    // cart.setImg_url(findImageMapper.findImage(cart.getImg_url()));
                }
                commentView.add(cart);
                a1.add(cart.getId());
                n--;
            }
            while(n!=0){
                cart=cartMapper.findone(id,0,1);
                for(int i=0;i<a1.size();i++){
                    if(cart==null)
                        break;
                    if(cart.getId()==a1.get(i)){
                        cart=cartMapper.findone(id,Integer.valueOf(a1.get(i).toString()),1);
                        i=-1;
                    }
                }
                if(cart.getImg_url()!=null)
                {
                    String[] address = cart.getImg_url().split(",");
                    cart.setImg_url(address[0]);
                    // cart.setImg_url(findImageMapper.findImage(cart.getImg_url()));
                }
                commentView.add(cart);
                n--;
            }
            return commentView;
        }
}

