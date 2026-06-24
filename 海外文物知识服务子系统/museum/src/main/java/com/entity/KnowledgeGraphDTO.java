package com.entity;

import lombok.Data;
import java.io.Serializable;
import java.util.List;
import java.util.Map;

@Data
public class KnowledgeGraphDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    private List<GraphNode> nodes;

    private List<GraphEdge> edges;

    private Map<String, Long> categoryCounts;

    public List<GraphNode> getNodes() { return nodes; }
    public void setNodes(List<GraphNode> nodes) { this.nodes = nodes; }
    public List<GraphEdge> getEdges() { return edges; }
    public void setEdges(List<GraphEdge> edges) { this.edges = edges; }
    public Map<String, Long> getCategoryCounts() { return categoryCounts; }
    public void setCategoryCounts(Map<String, Long> categoryCounts) { this.categoryCounts = categoryCounts; }

    @Data
    public static class GraphNode implements Serializable {
        private String id;
        private String name;
        private String category;
        private String value;
        private Integer symbolSize;
        private String color;

        public String getId() { return id; }
        public void setId(String id) { this.id = id; }
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }
        public String getCategory() { return category; }
        public void setCategory(String category) { this.category = category; }
        public String getValue() { return value; }
        public void setValue(String value) { this.value = value; }
        public Integer getSymbolSize() { return symbolSize; }
        public void setSymbolSize(Integer symbolSize) { this.symbolSize = symbolSize; }
        public String getColor() { return color; }
        public void setColor(String color) { this.color = color; }

        public GraphNode() {}

        public GraphNode(String id, String name, String category) {
            this.id = id;
            this.name = name;
            this.category = category;
            this.symbolSize = calculateSize(category);
            this.color = calculateColor(category);
        }

        public GraphNode(String id, String name, String category, int count) {
            this.id = id;
            this.name = name;
            this.category = category;
            this.symbolSize = calculateSizeByCount(category, count);
            this.color = calculateColor(category);
            this.value = String.valueOf(count);
        }

        private Integer calculateSize(String category) {
            switch (category) {
                case "relic": return 50;
                case "artist": return 40;
                case "dynasty": return 38;
                case "museum": return 36;
                case "material": return 30;
                case "type": return 30;
                case "location": return 28;
                case "culture": return 28;
                default: return 22;
            }
        }

        private Integer calculateSizeByCount(String category, int count) {
            int base;
            switch (category) {
                case "museum": base = 30; break;
                case "dynasty": base = 28; break;
                case "artist": base = 26; break;
                case "material": base = 22; break;
                case "type": base = 22; break;
                case "location": base = 20; break;
                case "culture": base = 20; break;
                case "relic": base = 35; break;
                default: base = 18; break;
            }
            return base + Math.min(count / 20, 50);
        }

        private String calculateColor(String category) {
            switch (category) {
                case "relic": return "#FF6B6B";
                case "artist": return "#4ECDC4";
                case "dynasty": return "#45B7D1";
                case "museum": return "#FFA07A";
                case "material": return "#98D8C8";
                case "type": return "#C39BD3";
                case "culture": return "#F7DC6F";
                case "location": return "#85C1E9";
                default: return "#BBBBBB";
            }
        }
    }

    @Data
    public static class GraphEdge implements Serializable {
        private String source;
        private String target;
        private String relationType;
        private String label;
        private Integer value;

        public String getSource() { return source; }
        public void setSource(String source) { this.source = source; }
        public String getTarget() { return target; }
        public void setTarget(String target) { this.target = target; }
        public String getRelationType() { return relationType; }
        public void setRelationType(String relationType) { this.relationType = relationType; }
        public String getLabel() { return label; }
        public void setLabel(String label) { this.label = label; }
        public Integer getValue() { return value; }
        public void setValue(Integer value) { this.value = value; }

        public GraphEdge() {}

        public GraphEdge(String source, String target, String relationType) {
            this.source = source;
            this.target = target;
            this.relationType = relationType;
            this.label = relationType;
        }

        public GraphEdge(String source, String target, String relationType, int value) {
            this.source = source;
            this.target = target;
            this.relationType = relationType;
            this.label = relationType;
            this.value = value;
        }
    }
}
