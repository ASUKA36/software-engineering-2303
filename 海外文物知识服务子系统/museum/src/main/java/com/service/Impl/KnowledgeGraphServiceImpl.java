package com.service.Impl;

import com.entity.KnowledgeGraphDTO;
import com.service.IKnowledgeGraphService;
import org.neo4j.driver.*;
import org.neo4j.driver.Record;
import org.neo4j.driver.types.Node;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class KnowledgeGraphServiceImpl implements IKnowledgeGraphService {

    private static final Logger log = LoggerFactory.getLogger(KnowledgeGraphServiceImpl.class);

    @Autowired
    private Driver neo4jDriver;

    private static final Map<String, String> LABEL_CATEGORY_MAP = new LinkedHashMap<>();
    private static final Map<String, String> RELATION_LABEL_MAP = new LinkedHashMap<>();

    static {
        LABEL_CATEGORY_MAP.put("Museum", "museum");
        LABEL_CATEGORY_MAP.put("Dynasty", "dynasty");
        LABEL_CATEGORY_MAP.put("Artist", "artist");
        LABEL_CATEGORY_MAP.put("Material", "material");
        LABEL_CATEGORY_MAP.put("ArtifactType", "type");
        LABEL_CATEGORY_MAP.put("Location", "location");
        LABEL_CATEGORY_MAP.put("Culture", "culture");
        LABEL_CATEGORY_MAP.put("Artifact", "relic");
        LABEL_CATEGORY_MAP.put("Entity", "entity");

        RELATION_LABEL_MAP.put("belongsToMuseum", "收藏于");
        RELATION_LABEL_MAP.put("belongsToDynasty", "属于朝代");
        RELATION_LABEL_MAP.put("createdBy", "创作者");
        RELATION_LABEL_MAP.put("usesMaterial", "使用材质");
        RELATION_LABEL_MAP.put("hasPrimaryMaterial", "主材质");
        RELATION_LABEL_MAP.put("hasType", "文物类型");
        RELATION_LABEL_MAP.put("hasCulture", "文化标签");
        RELATION_LABEL_MAP.put("locatedIn", "位于");
    }

    private static final String[][] COOCCURRENCE_PAIRS = {
        {"Dynasty", "belongsToDynasty", "Museum", "belongsToMuseum", "朝代-博物馆"},
        {"Dynasty", "belongsToDynasty", "ArtifactType", "hasType", "朝代-类型"},
        {"Dynasty", "belongsToDynasty", "Material", "hasPrimaryMaterial", "朝代-材质"},
        {"Dynasty", "belongsToDynasty", "Artist", "createdBy", "朝代-作者"},
        {"Museum", "belongsToMuseum", "ArtifactType", "hasType", "博物馆-类型"},
        {"Museum", "belongsToMuseum", "Material", "hasPrimaryMaterial", "博物馆-材质"},
        {"Museum", "belongsToMuseum", "Artist", "createdBy", "博物馆-作者"},
        {"Museum", "belongsToMuseum", "Location", "locatedIn", "博物馆-地点"},
        {"ArtifactType", "hasType", "Material", "hasPrimaryMaterial", "类型-材质"},
        {"ArtifactType", "hasType", "Culture", "hasCulture", "类型-文化"},
        {"Material", "hasPrimaryMaterial", "Culture", "hasCulture", "材质-文化"},
        {"Dynasty", "belongsToDynasty", "Culture", "hasCulture", "朝代-文化"},
        {"Dynasty", "belongsToDynasty", "Location", "locatedIn", "朝代-地点"},
    };

    @Override
    public KnowledgeGraphDTO getKnowledgeGraph(String keyword) {
        KnowledgeGraphDTO graphDTO = new KnowledgeGraphDTO();
        List<KnowledgeGraphDTO.GraphNode> nodes = new ArrayList<>();
        List<KnowledgeGraphDTO.GraphEdge> edges = new ArrayList<>();

        try {
            if (keyword != null && !keyword.trim().isEmpty()) {
                buildSearchGraph(keyword.trim(), nodes, edges);
                Map<String, Long> searchCounts = computeCategoryCountsFromNodes(nodes);
                Map<String, Long> totalCounts = queryCategoryCounts();
                Map<String, Long> mergedCounts = new LinkedHashMap<>();
                for (String key : totalCounts.keySet()) {
                    mergedCounts.put(key + "Total", totalCounts.get(key));
                }
                for (String key : searchCounts.keySet()) {
                    mergedCounts.put(key, searchCounts.get(key));
                }
                graphDTO.setCategoryCounts(mergedCounts);
            } else {
                buildEntityOverviewGraph(nodes, edges);
                graphDTO.setCategoryCounts(queryCategoryCounts());
            }
        } catch (Exception e) {
            log.error("获取知识图谱失败", e);
        }

        graphDTO.setNodes(nodes);
        graphDTO.setEdges(edges);
        return graphDTO;
    }

    @Override
    public KnowledgeGraphDTO getRelicKnowledgeGraph(String relicName) {
        return getKnowledgeGraph(relicName);
    }

    private String resolveCategory(Node node) {
        for (String label : LABEL_CATEGORY_MAP.keySet()) {
            if (node.hasLabel(label)) {
                return LABEL_CATEGORY_MAP.get(label);
            }
        }
        return "entity";
    }

    private String getNodeName(Node node) {
        boolean isArtifact = node.hasLabel("Artifact");
        if (isArtifact) {
            if (!node.get("title").isNull() && !node.get("title").asString().trim().isEmpty())
                return node.get("title").asString();
            if (!node.get("name").isNull() && !node.get("name").asString().trim().isEmpty())
                return node.get("name").asString();
            if (!node.get("artifact_id").isNull() && !node.get("artifact_id").asString().trim().isEmpty())
                return node.get("artifact_id").asString();
        } else {
            if (!node.get("name").isNull() && !node.get("name").asString().trim().isEmpty())
                return node.get("name").asString();
            if (!node.get("title").isNull() && !node.get("title").asString().trim().isEmpty())
                return node.get("title").asString();
        }
        return "Unknown";
    }

    private String getRelationLabel(String relType) {
        return RELATION_LABEL_MAP.getOrDefault(relType, relType);
    }

    private void buildEntityOverviewGraph(List<KnowledgeGraphDTO.GraphNode> nodes, List<KnowledgeGraphDTO.GraphEdge> edges) {
        try (Session session = neo4jDriver.session()) {
            Set<String> addedNodeIds = new HashSet<>();
            Map<String, String> uriToNodeId = new HashMap<>();

            String[] entityLabels = {"Museum", "Dynasty", "Artist", "Material", "ArtifactType", "Location", "Culture"};
            for (String label : entityLabels) {
                String category = LABEL_CATEGORY_MAP.get(label);
                try {
                    Result result = session.run(
                        "MATCH (n:`" + label + "`) " +
                        "OPTIONAL MATCH (n)<-[r]-() " +
                        "WITH n.name AS name, n.uri AS uri, count(r) AS relCount " +
                        "RETURN name, uri, relCount " +
                        "ORDER BY relCount DESC LIMIT 200"
                    );
                    while (result.hasNext()) {
                        Record record = result.next();
                        String name = record.get("name").isNull() ? label : record.get("name").asString();
                        String uri = record.get("uri").isNull() ? name : record.get("uri").asString();
                        int relCount = record.get("relCount").isNull() ? 0 : record.get("relCount").asInt();

                        String nodeId = category + "_" + uri;
                        if (addedNodeIds.add(nodeId)) {
                            uriToNodeId.put(uri, nodeId);
                            nodes.add(new KnowledgeGraphDTO.GraphNode(nodeId, name, category, relCount));
                        }
                    }
                } catch (Exception e) {
                    log.error("查询标签 {} 失败: {}", label, e.getMessage());
                }
            }

            try {
                Result artifactResult = session.run(
                    "MATCH (n:Artifact) " +
                    "OPTIONAL MATCH (n)-[r]-() " +
                    "WITH CASE WHEN n.title IS NOT NULL THEN n.title " +
                    "     WHEN n.name IS NOT NULL THEN n.name " +
                    "     ELSE n.artifact_id END AS name, " +
                    "     n.uri AS uri, count(r) AS relCount " +
                    "RETURN name, uri, relCount " +
                    "ORDER BY relCount DESC LIMIT 80"
                );
                while (artifactResult.hasNext()) {
                    Record record = artifactResult.next();
                    String name = record.get("name").isNull() ? "Artifact" : record.get("name").asString();
                    String uri = record.get("uri").isNull() ? name : record.get("uri").asString();
                    int relCount = record.get("relCount").isNull() ? 0 : record.get("relCount").asInt();

                    String nodeId = "relic_" + uri;
                    if (addedNodeIds.add(nodeId)) {
                        uriToNodeId.put(uri, nodeId);
                        nodes.add(new KnowledgeGraphDTO.GraphNode(nodeId, name, "relic", relCount));
                    }
                }
            } catch (Exception e) {
                log.error("查询Artifact节点失败: {}", e.getMessage());
            }

            String[] artifactRelTypes = {"belongsToMuseum", "belongsToDynasty", "createdBy", "hasPrimaryMaterial", "hasType", "hasCulture", "locatedIn"};
            for (String relType : artifactRelTypes) {
                try {
                    Result artEdgeResult = session.run(
                        "MATCH (art:Artifact)-[:`" + relType + "`]->(b) " +
                        "WITH art.uri AS artUri, b.uri AS bUri " +
                        "RETURN artUri, bUri LIMIT 300"
                    );
                    while (artEdgeResult.hasNext()) {
                        Record record = artEdgeResult.next();
                        String artUri = record.get("artUri").isNull() ? "" : record.get("artUri").asString();
                        String bUri = record.get("bUri").isNull() ? "" : record.get("bUri").asString();

                        String sourceId = uriToNodeId.get(artUri);
                        String targetId = uriToNodeId.get(bUri);

                        if (sourceId != null && targetId != null) {
                            edges.add(new KnowledgeGraphDTO.GraphEdge(sourceId, targetId, getRelationLabel(relType)));
                        }
                    }
                } catch (Exception e) {
                    log.error("查询Artifact关系 {} 失败: {}", relType, e.getMessage());
                }
            }

            for (String[] pair : COOCCURRENCE_PAIRS) {
                String labelA = pair[0];
                String relA = pair[1];
                String labelB = pair[2];
                String relB = pair[3];
                String edgeLabel = pair[4];

                try {
                    Result cooccResult = session.run(
                        "MATCH (a:`" + labelA + "`)<-[:`" + relA + "`]-(art:Artifact)-[:`" + relB + "`]->(b:`" + labelB + "`) " +
                        "WITH a.name AS aName, a.uri AS aUri, b.name AS bName, b.uri AS bUri, count(art) AS cnt " +
                        "RETURN aName, aUri, bName, bUri, cnt " +
                        "ORDER BY cnt DESC LIMIT 500"
                    );
                    while (cooccResult.hasNext()) {
                        Record record = cooccResult.next();
                        String aUri = record.get("aUri").asString();
                        String bUri = record.get("bUri").asString();
                        int cnt = record.get("cnt").asInt();

                        String sourceId = uriToNodeId.get(aUri);
                        String targetId = uriToNodeId.get(bUri);

                        if (sourceId != null && targetId != null) {
                            edges.add(new KnowledgeGraphDTO.GraphEdge(sourceId, targetId, edgeLabel, cnt));
                        }
                    }
                } catch (Exception e) {
                    log.error("查询共现关系 {}-{} 失败: {}", labelA, labelB, e.getMessage());
                }
            }
        } catch (Exception e) {
            log.error("Neo4j session 失败", e);
        }
    }

    private void buildSearchGraph(String keyword, List<KnowledgeGraphDTO.GraphNode> nodes, List<KnowledgeGraphDTO.GraphEdge> edges) {
        try (Session session = neo4jDriver.session()) {
            Set<String> addedNodeIds = new HashSet<>();
            Map<String, String> uriToNodeId = new HashMap<>();

            String[] entityLabels = {"Museum", "Dynasty", "Artist", "Material", "ArtifactType", "Location", "Culture"};
            String[] artifactRelTypes = {"belongsToMuseum", "belongsToDynasty", "createdBy", "hasPrimaryMaterial", "hasType", "hasCulture", "locatedIn"};

            for (String label : entityLabels) {
                String category = LABEL_CATEGORY_MAP.get(label);
                try {
                    Result result = session.run(
                        "MATCH (n:`" + label + "`) WHERE n.name CONTAINS $keyword " +
                        "OPTIONAL MATCH (n)<-[r]-() " +
                        "WITH n.name AS name, n.uri AS uri, count(r) AS relCount " +
                        "RETURN name, uri, relCount " +
                        "ORDER BY relCount DESC LIMIT 50",
                        Values.parameters("keyword", keyword)
                    );
                    while (result.hasNext()) {
                        Record record = result.next();
                        String name = record.get("name").isNull() ? label : record.get("name").asString();
                        String uri = record.get("uri").isNull() ? name : record.get("uri").asString();
                        int relCount = record.get("relCount").isNull() ? 0 : record.get("relCount").asInt();

                        String nodeId = category + "_" + uri;
                        if (addedNodeIds.add(nodeId)) {
                            uriToNodeId.put(uri, nodeId);
                            nodes.add(new KnowledgeGraphDTO.GraphNode(nodeId, name, category, relCount));
                        }
                    }
                } catch (Exception e) {
                    log.error("搜索标签 {} 失败: {}", label, e.getMessage());
                }
            }

            try {
                Result artifactResult = session.run(
                    "MATCH (n:Artifact) WHERE n.title CONTAINS $keyword OR n.name CONTAINS $keyword " +
                    "OPTIONAL MATCH (n)-[r]-() " +
                    "WITH CASE WHEN n.title IS NOT NULL THEN n.title " +
                    "     WHEN n.name IS NOT NULL THEN n.name " +
                    "     ELSE n.artifact_id END AS name, " +
                    "     n.uri AS uri, count(r) AS relCount " +
                    "RETURN name, uri, relCount " +
                    "ORDER BY relCount DESC LIMIT 50",
                    Values.parameters("keyword", keyword)
                );
                while (artifactResult.hasNext()) {
                    Record record = artifactResult.next();
                    String name = record.get("name").isNull() ? "Artifact" : record.get("name").asString();
                    String uri = record.get("uri").isNull() ? name : record.get("uri").asString();
                    int relCount = record.get("relCount").isNull() ? 0 : record.get("relCount").asInt();

                    String nodeId = "relic_" + uri;
                    if (addedNodeIds.add(nodeId)) {
                        uriToNodeId.put(uri, nodeId);
                        nodes.add(new KnowledgeGraphDTO.GraphNode(nodeId, name, "relic", relCount));
                    }
                }
            } catch (Exception e) {
                log.error("搜索Artifact节点失败: {}", e.getMessage());
            }

            if (nodes.isEmpty()) {
                buildEntityOverviewGraph(nodes, edges);
                return;
            }

            for (String relType : artifactRelTypes) {
                try {
                    String targetLabel = getTargetLabelForRelType(relType);
                    if (targetLabel == null) continue;

                    Result artEdgeResult = session.run(
                        "MATCH (art:Artifact)-[:`" + relType + "`]->(b:`" + targetLabel + "`) " +
                        "WHERE art.uri IN $artUris OR b.uri IN $entityUris " +
                        "WITH art.uri AS artUri, art.title AS artTitle, art.name AS artName, art.artifact_id AS artId, " +
                        "     b.uri AS bUri, b.name AS bName " +
                        "RETURN artUri, artTitle, artName, artId, bUri, bName LIMIT 300",
                        Values.parameters(
                            "artUris", uriToNodeId.keySet().stream().filter(u -> true).collect(java.util.stream.Collectors.toList()),
                            "entityUris", uriToNodeId.keySet().stream().collect(java.util.stream.Collectors.toList())
                        )
                    );
                    while (artEdgeResult.hasNext()) {
                        Record record = artEdgeResult.next();
                        String artUri = record.get("artUri").isNull() ? "" : record.get("artUri").asString();
                        String bUri = record.get("bUri").isNull() ? "" : record.get("bUri").asString();

                        if (artUri.isEmpty() || bUri.isEmpty()) continue;

                        String artTitle = record.get("artTitle").isNull() ? null : record.get("artTitle").asString();
                        String artName = record.get("artName").isNull() ? null : record.get("artName").asString();
                        String artId = record.get("artId").isNull() ? null : record.get("artId").asString();
                        String bName = record.get("bName").isNull() ? targetLabel : record.get("bName").asString();

                        String artNodeId = "relic_" + artUri;
                        if (addedNodeIds.add(artNodeId)) {
                            String displayName = artTitle != null ? artTitle : (artName != null ? artName : (artId != null ? artId : "Artifact"));
                            uriToNodeId.put(artUri, artNodeId);
                            nodes.add(new KnowledgeGraphDTO.GraphNode(artNodeId, displayName, "relic", 0));
                        }

                        String bCategory = LABEL_CATEGORY_MAP.get(targetLabel);
                        String bNodeId = bCategory + "_" + bUri;
                        if (addedNodeIds.add(bNodeId)) {
                            uriToNodeId.put(bUri, bNodeId);
                            nodes.add(new KnowledgeGraphDTO.GraphNode(bNodeId, bName, bCategory, 0));
                        }

                        String edgeLabel = getRelationLabel(relType);
                        edges.add(new KnowledgeGraphDTO.GraphEdge(artNodeId, bNodeId, edgeLabel));
                    }
                } catch (Exception e) {
                    log.error("搜索Artifact关系 {} 失败: {}", relType, e.getMessage());
                }
            }

            for (String[] pair : COOCCURRENCE_PAIRS) {
                String labelA = pair[0];
                String relA = pair[1];
                String labelB = pair[2];
                String relB = pair[3];
                String edgeLabel = pair[4];

                try {
                    Result cooccResult = session.run(
                        "MATCH (a:`" + labelA + "`)<-[:`" + relA + "`]-(art:Artifact)-[:`" + relB + "`]->(b:`" + labelB + "`) " +
                        "WHERE a.uri IN $uris OR b.uri IN $uris " +
                        "WITH a.name AS aName, a.uri AS aUri, b.name AS bName, b.uri AS bUri, count(art) AS cnt " +
                        "RETURN aName, aUri, bName, bUri, cnt " +
                        "ORDER BY cnt DESC LIMIT 500",
                        Values.parameters("uris", new ArrayList<>(uriToNodeId.keySet()))
                    );
                    while (cooccResult.hasNext()) {
                        Record record = cooccResult.next();
                        String aUri = record.get("aUri").asString();
                        String bUri = record.get("bUri").asString();
                        int cnt = record.get("cnt").asInt();

                        String sourceId = uriToNodeId.get(aUri);
                        String targetId = uriToNodeId.get(bUri);

                        if (sourceId != null && targetId != null) {
                            edges.add(new KnowledgeGraphDTO.GraphEdge(sourceId, targetId, edgeLabel, cnt));
                        }
                    }
                } catch (Exception e) {
                    log.error("搜索共现关系 {}-{} 失败: {}", labelA, labelB, e.getMessage());
                }
            }
        } catch (Exception e) {
            log.error("搜索图谱失败", e);
        }
    }

    private String getTargetLabelForRelType(String relType) {
        switch (relType) {
            case "belongsToMuseum": return "Museum";
            case "belongsToDynasty": return "Dynasty";
            case "createdBy": return "Artist";
            case "hasPrimaryMaterial": return "Material";
            case "hasType": return "ArtifactType";
            case "hasCulture": return "Culture";
            case "locatedIn": return "Location";
            default: return null;
        }
    }

    private String resolveCategoryFromLabels(List<String> labels) {
        String[] priority = {"Museum", "Dynasty", "Artist", "Material", "ArtifactType", "Location", "Culture", "Artifact"};
        for (String label : priority) {
            if (labels.contains(label)) {
                return LABEL_CATEGORY_MAP.get(label);
            }
        }
        return "entity";
    }

    private int countRelationships(Session session, Node node) {
        try {
            Result countResult = session.run(
                "MATCH (n)-[r]-() WHERE id(n) = $nodeId RETURN count(r) AS cnt",
                Values.parameters("nodeId", node.id())
            );
            if (countResult.hasNext()) {
                return countResult.next().get("cnt").asInt();
            }
        } catch (Exception e) {
            log.debug("统计关系数失败", e);
        }
        return 0;
    }

    private Map<String, Long> queryCategoryCounts() {
        Map<String, Long> counts = new LinkedHashMap<>();
        try (Session session = neo4jDriver.session()) {
            String[][] labelCategoryPairs = {
                {"Museum", "museum"}, {"Dynasty", "dynasty"}, {"Artist", "artist"},
                {"Material", "material"}, {"ArtifactType", "type"}, {"Location", "location"},
                {"Culture", "culture"}, {"Artifact", "relic"}
            };
            for (String[] pair : labelCategoryPairs) {
                try {
                    Result result = session.run("MATCH (n:`" + pair[0] + "`) RETURN count(n) AS cnt");
                    if (result.hasNext()) {
                        counts.put(pair[1], result.next().get("cnt").asLong());
                    }
                } catch (Exception e) {
                    log.error("统计 {} 数量失败: {}", pair[0], e.getMessage());
                    counts.put(pair[1], 0L);
                }
            }
        } catch (Exception e) {
            log.error("查询类别总数失败", e);
        }
        return counts;
    }

    private Map<String, Long> computeCategoryCountsFromNodes(List<KnowledgeGraphDTO.GraphNode> nodes) {
        Map<String, Long> counts = new LinkedHashMap<>();
        for (KnowledgeGraphDTO.GraphNode node : nodes) {
            String cat = node.getCategory();
            counts.put(cat, counts.getOrDefault(cat, 0L) + 1);
        }
        return counts;
    }
}
