package com.mapper;
import com.entity.Comment;
import com.entity.CommentView;
import org.apache.ibatis.annotations.Mapper;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;

@Repository
@Mapper
public interface CommentMapper {
    /**
     * 插入评论数据
     * @param comment 评论实体
     * @return 受影响的行数
     */
    Integer insert(Comment comment);

    /**
     * 软删除评论（修改状态为0）
     * @param commentId 评论ID
     * @return 受影响的行数
     */
    Integer softDelete(Long commentId);

    /**
     * 物理删除评论
     * @param commentId 评论ID
     * @return 受影响的行数
     */
    Integer delete(Long commentId);

    /**
     * 根据评论ID查询评论
     * @param commentId 评论ID
     * @return 评论实体，无则返回null
     */
    Comment findByCid(Long commentId);

    /**
     * 根据文物查询评论（只显示已审核通过且状态正常的）
     * @param museumId 博物馆ID
     * @param objectId 文物编号
     * @return 评论列表
     */
    List<CommentView> findByArtifact(Integer museumId, String objectId);

    /**
     * 根据用户ID查询所有评论
     * @param userId 用户ID
     * @return 评论列表
     */
    List<CommentView> findByUserId(Long userId);

    /**
     * 根据用户ID和文物查询评论
     * @param userId 用户ID
     * @param museumId 博物馆ID
     * @param objectId 文物编号
     * @return 评论列表
     */
    List<CommentView> findByUserIdAndArtifact(Long userId, Integer museumId, String objectId);
}
