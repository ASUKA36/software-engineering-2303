package com.util;

import java.util.*;

/**
 * 内容审核引擎
 * 实现与后台一致的审核算法
 * 
 * 使用方式：
 * 1. 创建引擎实例
 * 2. 通过 loadSensitiveWords() 和 loadReviewStrategy() 加载配置
 * 3. 调用 computeRisk() 计算风险分
 * 4. 调用 applyCommentReview() 获取审核结果
 */
public class ContentReviewEngine {

    /**
     * 敏感词级别
     */
    public enum SensitiveLevel {
        LIGHT,   // 普通敏感词
        SEVERE   // 严重敏感词（命中即拒绝）
    }

    /**
     * 审核动作
     */
    public enum ReviewAction {
        AUTO_APPROVE,      // 自动通过
        MANUAL_REVIEW,     // 人工复审
        AUTO_REJECT        // 自动拒绝
    }

    /**
     * 敏感词记录
     */
    public static class SensitiveWord {
        public String word;
        public SensitiveLevel level;

        public SensitiveWord(String word, SensitiveLevel level) {
            this.word = word;
            this.level = level;
        }
    }

    /**
     * 审核策略配置
     */
    public static class ReviewStrategy {
        public int lowRiskMaxScore = 20;
        public int mediumRiskMaxScore = 60;
        public ReviewAction lowRiskAction = ReviewAction.AUTO_APPROVE;
        public ReviewAction mediumRiskAction = ReviewAction.MANUAL_REVIEW;
        public ReviewAction highRiskAction = ReviewAction.AUTO_REJECT;

        public ReviewStrategy() {}

        public ReviewStrategy(int lowRiskMaxScore, int mediumRiskMaxScore,
                             ReviewAction lowRiskAction, ReviewAction mediumRiskAction, ReviewAction highRiskAction) {
            this.lowRiskMaxScore = lowRiskMaxScore;
            this.mediumRiskMaxScore = mediumRiskMaxScore;
            this.lowRiskAction = lowRiskAction;
            this.mediumRiskAction = mediumRiskAction;
            this.highRiskAction = highRiskAction;
        }
    }

    /**
     * 审核结果
     */
    public static class ReviewResult {
        public int riskScore;                    // 风险分 0-100
        public ReviewAction action;              // 审核动作
        public List<String> hitWords;            // 命中的敏感词
        public String rejectMessage;             // 拒绝时的提示文案

        public ReviewResult(int riskScore, ReviewAction action, List<String> hitWords) {
            this.riskScore = riskScore;
            this.action = action;
            this.hitWords = hitWords;
            if (action == ReviewAction.AUTO_REJECT) {
                if (hitWords != null && !hitWords.isEmpty()) {
                    this.rejectMessage = "内容违规无法发布，请修改后重试（命中：" + String.join(",", hitWords) + "）";
                } else {
                    this.rejectMessage = "内容违规无法发布，请修改后重试";
                }
            }
        }
    }

    private List<SensitiveWord> sensitiveWords = new ArrayList<>();
    private ReviewStrategy strategy = new ReviewStrategy();

    /**
     * 加载敏感词列表
     * @param words 敏感词列表（word, level）
     */
    public void loadSensitiveWords(List<SensitiveWord> words) {
        this.sensitiveWords = new ArrayList<>(words);
        // 按 word 升序排序（与后台 JPA 一致）
        this.sensitiveWords.sort(Comparator.comparing(w -> w.word));
    }

    /**
     * 加载审核策略
     * @param strategy 策略配置
     */
    public void loadReviewStrategy(ReviewStrategy strategy) {
        this.strategy = strategy != null ? strategy : new ReviewStrategy();
    }

    /**
     * 计算风险分
     * @param text 文本内容
     * @param url URL（可选）
     * @param isImage 是否图片（当前不需要实现）
     * @return 风险分 0-100 和命中的敏感词
     */
    public RiskScoreResult computeRisk(String text, String url, boolean isImage) {
        int score = 0;
        List<String> hitWords = new ArrayList<>();
        
        if (text == null) {
            text = "";
        }
        
        String contentToCheck = (text + " " + (url != null ? url : "")).toLowerCase();

        for (SensitiveWord word : sensitiveWords) {
            String lowerWord = word.word.toLowerCase();
            if (contentToCheck.contains(lowerWord)) {
                hitWords.add(word.word);
                
                if (word.level == SensitiveLevel.SEVERE) {
                    // 命中严重敏感词，立即返回 100 分
                    return new RiskScoreResult(100, hitWords);
                }
                
                // 普通敏感词，每出现一次 +10 分
                // 统计出现次数
                int count = 0;
                int index = 0;
                while ((index = contentToCheck.indexOf(lowerWord, index)) != -1) {
                    count++;
                    index += lowerWord.length();
                }
                score += count * 10;
            }
        }

        // 最终分数限制在 0-100
        score = Math.min(100, Math.max(0, score));
        
        return new RiskScoreResult(score, hitWords);
    }

    /**
     * 风险分计算结果
     */
    public static class RiskScoreResult {
        public int score;
        public List<String> hitWords;

        public RiskScoreResult(int score, List<String> hitWords) {
            this.score = score;
            this.hitWords = hitWords;
        }
    }

    /**
     * 应用评论审核策略
     * @param score 风险分
     * @param hitWords 命中的敏感词
     * @return 审核结果
     */
    public ReviewResult applyCommentReview(int score, List<String> hitWords) {
        ReviewAction action;
        
        if (score <= strategy.lowRiskMaxScore) {
            action = strategy.lowRiskAction;
        } else if (score <= strategy.mediumRiskMaxScore) {
            action = strategy.mediumRiskAction;
        } else {
            action = strategy.highRiskAction;
        }
        
        return new ReviewResult(score, action, hitWords);
    }

    /**
     * 完整的评论审核流程
     * @param text 评论内容
     * @return 审核结果
     */
    public ReviewResult reviewComment(String text) {
        RiskScoreResult riskResult = computeRisk(text, null, false);
        return applyCommentReview(riskResult.score, riskResult.hitWords);
    }

    /**
     * 检查是否命中敏感词（简化版，用于快速判断）
     * @param text 文本内容
     * @return 是否命中
     */
    public boolean containsSensitiveWord(String text) {
        if (text == null) {
            return false;
        }
        String lowerText = text.toLowerCase();
        for (SensitiveWord word : sensitiveWords) {
            if (lowerText.contains(word.word.toLowerCase())) {
                return true;
            }
        }
        return false;
    }
}