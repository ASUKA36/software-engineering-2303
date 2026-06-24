package com.repository;

import com.entity.Product_neo4j;
import org.springframework.data.neo4j.repository.Neo4jRepository;
import org.springframework.data.neo4j.repository.query.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

@Repository
public interface ProductRepository extends Neo4jRepository<Product_neo4j, Long> {
    
    /**
     * 查询文物的所有关联关系（三元组）
     * 实体ID格式: entity:artifact:{museum_id}:{object_id}
     */
    @Query("MATCH (r:artifact {id: $entityId})-[rel]->(target) RETURN r.id as subject, type(rel) as predicate, target.id as object")
    List<Map<String, Object>> findRelicRelationsById(String entityId);
    
    /**
     * 查询与文物相关的所有实体
     */
    @Query("MATCH (r:artifact {id: $entityId})--(related) RETURN related.id as entity")
    List<Map<String, Object>> findRelatedEntitiesById(String entityId);
    
    /**
     * 根据ID查找文物节点
     */
    @Query("MATCH (r:artifact {id: $entityId}) RETURN r")
    Product_neo4j findById(String entityId);
    
    /**
     * 查询文物的所有关联关系（包含标签属性）
     */
    @Query("MATCH (r:artifact {id: $entityId})-[rel]->(target) RETURN r.id as subject, type(rel) as predicate, coalesce(target.name, target.label, target.id) as object")
    List<Map<String, Object>> findRelicRelationsWithLabel(String entityId);
}
