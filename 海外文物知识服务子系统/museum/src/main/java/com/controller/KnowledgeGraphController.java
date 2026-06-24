package com.controller;

import com.entity.KnowledgeGraphDTO;
import com.service.IKnowledgeGraphService;
import com.util.JsonResult;
import org.neo4j.driver.Driver;
import org.neo4j.driver.Record;
import org.neo4j.driver.Result;
import org.neo4j.driver.Session;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("knowledge")
public class KnowledgeGraphController extends BaseController {
    
    @Autowired
    private IKnowledgeGraphService knowledgeGraphService;

    @Autowired
    private Driver neo4jDriver;
    
    @PostMapping("/graph")
    public JsonResult<KnowledgeGraphDTO> getKnowledgeGraph(@RequestBody Map<String, String> params) {
        JsonResult<KnowledgeGraphDTO> result = new JsonResult<>();
        try {
            String keyword = params.getOrDefault("keyword", "");
            KnowledgeGraphDTO graphData = knowledgeGraphService.getKnowledgeGraph(keyword);
            
            result.setData(graphData);
            result.setState(200);
            result.setMessage("获取知识图谱成功");
        } catch (Exception e) {
            result.setState(6000);
            result.setMessage("获取知识图谱失败：" + e.getMessage());
            e.printStackTrace();
        }
        return result;
    }
    
    @PostMapping("/relic-graph")
    public JsonResult<KnowledgeGraphDTO> getRelicKnowledgeGraph(@RequestBody Map<String, String> params) {
        JsonResult<KnowledgeGraphDTO> result = new JsonResult<>();
        try {
            String relicName = params.get("relicName");
            if (relicName == null || relicName.trim().isEmpty()) {
                result.setState(4000);
                result.setMessage("文物名称不能为空");
                return result;
            }
            
            KnowledgeGraphDTO graphData = knowledgeGraphService.getRelicKnowledgeGraph(relicName);
            
            result.setData(graphData);
            result.setState(200);
            result.setMessage("获取文物关联图谱成功");
        } catch (Exception e) {
            result.setState(6000);
            result.setMessage("获取文物关联图谱失败：" + e.getMessage());
            e.printStackTrace();
        }
        return result;
    }

    @GetMapping("/schema")
    public JsonResult<Map<String, Object>> getNeo4jSchema() {
        JsonResult<Map<String, Object>> result = new JsonResult<>();
        try (Session session = neo4jDriver.session()) {
            Map<String, Object> schema = new LinkedHashMap<>();

            List<String> labels = new ArrayList<>();
            Result labelResult = session.run("CALL db.labels()");
            while (labelResult.hasNext()) {
                Record record = labelResult.next();
                labels.add(record.get(0).asString());
            }
            schema.put("labels", labels);

            List<Map<String, Object>> labelCounts = new ArrayList<>();
            for (String label : labels) {
                Result countResult = session.run("MATCH (n:`" + label + "`) RETURN count(n) AS cnt");
                if (countResult.hasNext()) {
                    long cnt = countResult.next().get("cnt").asLong();
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("label", label);
                    item.put("count", cnt);
                    labelCounts.add(item);
                }
            }
            schema.put("labelCounts", labelCounts);

            List<String> relTypes = new ArrayList<>();
            Result relResult = session.run("CALL db.relationshipTypes()");
            while (relResult.hasNext()) {
                Record record = relResult.next();
                relTypes.add(record.get(0).asString());
            }
            schema.put("relationshipTypes", relTypes);

            List<Map<String, Object>> relCounts = new ArrayList<>();
            for (String relType : relTypes) {
                Result countResult = session.run(
                    "MATCH ()-[r:`" + relType + "`]->() RETURN count(r) AS cnt"
                );
                if (countResult.hasNext()) {
                    long cnt = countResult.next().get("cnt").asLong();
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("type", relType);
                    item.put("count", cnt);
                    relCounts.add(item);
                }
            }
            schema.put("relationshipCounts", relCounts);

            List<Map<String, Object>> sampleNodes = new ArrayList<>();
            for (String label : labels) {
                Result sampleResult = session.run(
                    "MATCH (n:`" + label + "`) RETURN n LIMIT 2"
                );
                while (sampleResult.hasNext()) {
                    Record record = sampleResult.next();
                    Map<String, Object> nodeProps = record.get("n").asNode().asMap();
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("label", label);
                    item.put("properties", nodeProps);
                    sampleNodes.add(item);
                }
            }
            schema.put("sampleNodes", sampleNodes);

            result.setData(schema);
            result.setState(200);
            result.setMessage("获取Neo4j Schema成功");
        } catch (Exception e) {
            result.setState(6000);
            result.setMessage("获取Neo4j Schema失败：" + e.getMessage());
            e.printStackTrace();
        }
        return result;
    }
}
