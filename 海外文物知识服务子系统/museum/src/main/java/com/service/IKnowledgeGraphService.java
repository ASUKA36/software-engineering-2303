package com.service;

import com.entity.KnowledgeGraphDTO;

/**
 * 知识图谱服务接口
 */
public interface IKnowledgeGraphService {
    
    /**
     * 获取知识图谱数据
     * @param keyword 搜索关键词（可选）
     * @return 知识图谱DTO（包含节点和边）
     */
    KnowledgeGraphDTO getKnowledgeGraph(String keyword);
    
    /**
     * 获取指定文物的关联图谱
     * @param relicName 文物名称
     * @return 知识图谱DTO
     */
    KnowledgeGraphDTO getRelicKnowledgeGraph(String relicName);
}
