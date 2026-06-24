package com.entity;

import java.util.ArrayList;
import java.util.List;

/**
 * 文物详情视图实体（包含评论和推荐信息）
 */
public class ProductView extends Product {
    
    /**
     * 评论列表
     */
    private ArrayList<CommentView> commentView;
    
    /**
     * 是否已收藏 (0=未收藏, 1=已收藏)
     */
    private int if_collect;
    
    /**
     * 推荐文物列表
     */
    private List<Cart> recommend;

    /**
     * 无参构造函数
     */
    public ProductView() {
        super();
    }

    /**
     * 带评论列表的构造函数
     */
    public ProductView(ArrayList<CommentView> commentView) {
        this.commentView = commentView;
    }

    public List<Cart> getRecommend() {
        return recommend;
    }

    public void setRecommend(List<Cart> recommend) {
        this.recommend = recommend;
    }

    public ArrayList<CommentView> getCommentView() {
        return commentView;
    }

    public void setCommentView(ArrayList<CommentView> commentView) {
        this.commentView = commentView;
    }

    public int getIf_collect() {
        return if_collect;
    }

    public void setIf_collect(int if_collect) {
        this.if_collect = if_collect;
    }

    @Override
    public String toString() {
        return "ProductView{" +
                "commentView=" + commentView +
                '}';
    }
}
