package com.service.Impl;

import com.entity.Comment;
import com.entity.CommentView;
import com.entity.ReviewStrategyConfig;
import com.entity.SensitiveWord;
import com.mapper.CommentMapper;
import com.mapper.ReviewStrategyConfigMapper;
import com.mapper.SensitiveWordMapper;
import com.service.ICommentService;
import com.service.exception.DeleteException;
import com.service.exception.DeleteLoss;
import com.service.exception.InsertException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class CommentServicelmpl implements ICommentService {
    @Autowired
    CommentMapper commentMapper;
    
    @Autowired
    SensitiveWordMapper sensitiveWordMapper;
    
    @Autowired
    ReviewStrategyConfigMapper reviewStrategyConfigMapper;

    private String stripHtml(String s) {
        if (s == null) return null;
        return s.replaceAll("<[^>]+>", "");
    }

    @Override
    public Long addComment(Long userId, Integer museumId, String objectId, String content) {
        // 1. 审核评论内容
        ReviewResult reviewResult = reviewCommentContent(content);
        
        if (reviewResult.isRejected()) {
            throw new InsertException(reviewResult.getRejectMessage());
        }

        // 2. 构建评论对象
        Comment comment = new Comment();
        comment.setUserId(userId);
        comment.setMuseumId(museumId);
        comment.setObjectId(objectId);
        comment.setContent(content);
        
        // 设置审核状态
        comment.setAuditStatus(reviewResult.getAuditStatus());
        comment.setAuditMethod(reviewResult.getAuditMethod());
        comment.setAutoAuditStatus(reviewResult.getRiskScore());
        comment.setSensitiveWordsHit(reviewResult.getHitWordsStr());

        // 3. 插入数据库
        Integer rows = commentMapper.insert(comment);
        if (rows != 1) {
            throw new InsertException("评论添加失败");
        }
        return comment.getCommentId();
    }

    /**
     * 审核评论内容
     * @param content 评论内容
     * @return 审核结果
     */
    private ReviewResult reviewCommentContent(String content) {
        // 1. 加载敏感词
        List<SensitiveWord> sensitiveWords = sensitiveWordMapper.findAllEnabled();
        
        // 2. 加载策略配置
        ReviewStrategyConfig strategyConfig = reviewStrategyConfigMapper.findById();
        if (strategyConfig == null) {
            strategyConfig = new ReviewStrategyConfig(); // 使用默认值
        }

        // 3. 计算风险分
        int riskScore = 0;
        List<String> hitWords = new ArrayList<>();
        
        if (content != null && !content.isEmpty()) {
            String lowerContent = content.toLowerCase();
            
            for (SensitiveWord word : sensitiveWords) {
                String lowerWord = word.getWord().toLowerCase();
                if (lowerContent.contains(lowerWord)) {
                    hitWords.add(word.getWord());
                    
                    if ("SEVERE".equals(word.getLevel())) {
                        // 命中严重敏感词，立即返回 100 分
                        return new ReviewResult(100, hitWords, strategyConfig);
                    }
                    
                    // 普通敏感词，每出现一次 +10 分
                    int count = 0;
                    int index = 0;
                    while ((index = lowerContent.indexOf(lowerWord, index)) != -1) {
                        count++;
                        index += lowerWord.length();
                    }
                    riskScore += count * 10;
                }
            }
        }
        
        // 限制分数在 0-100
        riskScore = Math.min(100, Math.max(0, riskScore));
        
        return new ReviewResult(riskScore, hitWords, strategyConfig);
    }

    /**
     * 审核结果内部类
     */
    private static class ReviewResult {
        private int riskScore;
        private List<String> hitWords;
        private boolean rejected;
        private String rejectMessage;
        private int auditStatus;
        private int auditMethod;

        public ReviewResult(int riskScore, List<String> hitWords, ReviewStrategyConfig strategy) {
            this.riskScore = riskScore;
            this.hitWords = hitWords;
            
            // 根据策略判断动作
            if (riskScore <= strategy.getLowRiskMaxScore()) {
                // 低风险：自动通过
                this.auditStatus = 1;
                this.auditMethod = 3;
                this.rejected = false;
            } else if (riskScore <= strategy.getMediumRiskMaxScore()) {
                // 中风险：人工复审
                this.auditStatus = 0;
                this.auditMethod = 1;
                this.rejected = false;
            } else {
                // 高风险：自动拒绝
                this.rejected = true;
                if (hitWords != null && !hitWords.isEmpty()) {
                    this.rejectMessage = "内容违规无法发布，请修改后重试（命中：" + String.join(",", hitWords) + "）";
                } else {
                    this.rejectMessage = "内容违规无法发布，请修改后重试";
                }
            }
        }

        public int getRiskScore() {
            return riskScore;
        }

        public List<String> getHitWords() {
            return hitWords;
        }

        public String getHitWordsStr() {
            return hitWords != null && !hitWords.isEmpty() ? String.join(",", hitWords) : null;
        }

        public boolean isRejected() {
            return rejected;
        }

        public String getRejectMessage() {
            return rejectMessage;
        }

        public int getAuditStatus() {
            return auditStatus;
        }

        public int getAuditMethod() {
            return auditMethod;
        }
    }

    @Override
    public void softDeleteComment(Long commentId) {
        Comment comment = commentMapper.findByCid(commentId);
        if (comment == null) {
            throw new DeleteLoss("未找到要删除的评论");
        }
        Integer rows = commentMapper.softDelete(commentId);
        if (rows != 1) {
            throw new DeleteException("删除评论失败");
        }
    }

    @Override
    public void deleteComment(Long commentId) {
        Comment comment = commentMapper.findByCid(commentId);
        if (comment == null) {
            throw new DeleteLoss("未找到要删除的评论");
        }
        Integer rows = commentMapper.delete(commentId);
        if (rows != 1) {
            throw new DeleteException("删除评论失败");
        }
    }

    @Override
    public List<CommentView> getCommentsByArtifact(Integer museumId, String objectId) {
        List<CommentView> list = commentMapper.findByArtifact(museumId, objectId);
        for (CommentView cv : list) {
            cv.setObjectName(stripHtml(cv.getObjectName()));
        }
        return list;
    }

    @Override
    public List<CommentView> getCommentsByUser(Long userId) {
        List<CommentView> list = commentMapper.findByUserId(userId);
        for (CommentView cv : list) {
            cv.setObjectName(stripHtml(cv.getObjectName()));
        }
        return list;
    }

    @Override
    public List<CommentView> getCommentsByUserAndArtifact(Long userId, Integer museumId, String objectId) {
        List<CommentView> list = commentMapper.findByUserIdAndArtifact(userId, museumId, objectId);
        for (CommentView cv : list) {
            cv.setObjectName(stripHtml(cv.getObjectName()));
        }
        return list;
    }
}