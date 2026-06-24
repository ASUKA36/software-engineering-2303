package com.service;

import com.entity.CommentView;

import java.util.List;

public interface ICommentService {
    /**
     * 添加评论
     * @param userId 用户ID
     * @param museumId 博物馆ID
     * @param objectId 文物编号
     * @param content 评论内容
     * @return 评论ID
     */
    Long addComment(Long userId, Integer museumId, String objectId, String content);

    /**
     * 软删除评论（修改状态为0）
     * @param commentId 评论ID
     */
    void softDeleteComment(Long commentId);

    /**
     * 物理删除评论
     * @param commentId 评论ID
     */
    void deleteComment(Long commentId);

    /**
     * 获取文物的评论列表（只显示已审核通过且状态正常的）
     * @param museumId 博物馆ID
     * @param objectId 文物编号
     * @return 评论列表
     */
    List<CommentView> getCommentsByArtifact(Integer museumId, String objectId);

    /**
     * 获取用户的所有评论
     * @param userId 用户ID
     * @return 评论列表
     */
    List<CommentView> getCommentsByUser(Long userId);

    /**
     * 获取用户在某文物的评论
     * @param userId 用户ID
     * @param museumId 博物馆ID
     * @param objectId 文物编号
     * @return 评论列表
     */
    List<CommentView> getCommentsByUserAndArtifact(Long userId, Integer museumId, String objectId);
}
