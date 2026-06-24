package com.controller;

import com.entity.*;
import com.service.CollectService;
import com.service.ICartService;
import com.service.ICommentService;
import com.service.IProductService;
import com.service.exception.CollectduplicateException;
import com.service.exception.CommentPermissionException;
import com.service.exception.InsertException;
import com.service.exception.ProductNotFoundException;
import com.util.JsonResult;
import org.neo4j.driver.Driver;
import org.neo4j.driver.Session;
import org.neo4j.driver.Result;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("search")
public class ProductController extends BaseController {

    @Autowired
    private IProductService iProductService;
    @Autowired
    private ICartService iCartService;
    @Autowired
    private ICommentService iCommentService;
    @Autowired
    private CollectService collectService;
    @Autowired
    private Driver neo4jDriver;

    /**
     * 文物详情页面
     * @param map 包含 museumId, objectId, uid
     * @return JsonResult<ProductView>
     */
    @RequestMapping("/searchById")
    public JsonResult<ProductView> findById(@RequestBody Map map){
        JsonResult<ProductView> result = new JsonResult<ProductView>();
        try{
            String museumIdStr = (String) map.get("museumId");
            String objectId = (String) map.get("objectId");
            String userid = (String) map.get("uid");

            int museumId = Integer.parseInt(museumIdStr);

            Product p = iProductService.findByProductId(museumId, objectId);
            ProductView pp = new ProductView();
            BeanUtils.copyProperties(p, pp);

            pp.setCommentView((ArrayList<CommentView>) iCommentService.getCommentsByArtifact(museumId, objectId));

            List<Cart> recommend = new ArrayList<Cart>();
            recommend = iCartService.SearchCommentView(
                p.getMuseum(),
                p.getDynasty(),
                p.getArtist(),
                p.getCulture(),
                BigInteger.valueOf(museumId)
            );
            pp.setRecommend(recommend);

            if(userid != null){
                Long userId = Long.parseLong(userid);
                Collect collect = collectService.findByUserIdAndArtifact(userId, museumId, objectId);
                if(collect != null) {
                    pp.setIf_collect(1);
                } else {
                    pp.setIf_collect(0);
                }
            }

            result.setData(pp);
            result.setState(200);
            result.setMessage("找到以下内容：");
        } catch (ProductNotFoundException e) {
            result.setState(6000);
            result.setMessage("抱歉，您查询的文物不存在！");
        } catch (Exception e) {
            result.setState(6000);
            result.setMessage("查询失败：" + e.getMessage());
        }
        return result;
    }

    /**
     * 评论文物
     */
    @RequestMapping("/searchById/comment")
    public JsonResult<Integer> comment(@RequestBody Map map) {
        JsonResult<Integer> result = new JsonResult<Integer>();
        try{
            String userid = (String) map.get("uid");
            String museumIdStr = (String) map.get("museumId");
            String objectId = (String) map.get("objectId");
            String content = (String) map.get("content");
            
            Long userId = Long.parseLong(userid);
            Integer museumId = Integer.parseInt(museumIdStr);
            
            iCommentService.addComment(userId, museumId, objectId, content);
            result.setData(1);
            result.setState(200);
            result.setMessage("评论成功");
        } catch(CommentPermissionException e) {
            result.setMessage("您已被限制评论");
            result.setState(3000);
        } catch(InsertException e) {
            result.setMessage("评论出现未知错误");
            result.setState(6000);
        }
        return result;
    }

    /**
     * 收藏文物
     */
    @RequestMapping("/searchById/collect")
    public JsonResult<Integer> collect(@RequestBody Map map) {
        JsonResult<Integer> result = new JsonResult<Integer>();
        try{
            String userid = (String) map.get("uid");
            String museumIdStr = (String) map.get("museumId");
            String objectId = (String) map.get("objectId");

            Long userId = Long.parseLong(userid);
            Integer museumId = Integer.parseInt(museumIdStr);

            Collect collect = new Collect();
            collect.setUserId(userId);
            collect.setMuseumId(museumId);
            collect.setObjectId(objectId);

            result.setData(collectService.addcollection(collect));
            result.setState(200);
            result.setMessage("收藏成功");
        } catch(CollectduplicateException e) {
            result.setMessage("请勿重复收藏！");
            result.setState(5000);
        } catch(Exception e) {
            result.setMessage("收藏失败：" + e.getMessage());
            result.setState(5000);
        }
        return result;
    }
    
    /**
     * 获取评论列表
     */
    @RequestMapping("/searchById/comment/list")
    public JsonResult<ArrayList<CommentView>> getCommentList(@RequestBody Map map) {
        JsonResult<ArrayList<CommentView>> result = new JsonResult<ArrayList<CommentView>>();
        try{
            String museumIdStr = (String) map.get("museumId");
            String objectId = (String) map.get("objectId");
            
            Integer museumId = Integer.parseInt(museumIdStr);
            ArrayList<CommentView> comments = (ArrayList<CommentView>) iCommentService.getCommentsByArtifact(museumId, objectId);
            result.setData(comments);
            result.setState(200);
            result.setMessage("获取评论成功");
        } catch(Exception e) {
            result.setMessage("获取评论失败：" + e.getMessage());
            result.setState(6000);
        }
        return result;
    }
    
    /**
     * 获取文物知识（从Neo4j知识图谱）
     */
    @RequestMapping("/search/knowledge")
    public JsonResult<List<Map<String, Object>>> getKnowledge(@RequestBody Map map) {
        JsonResult<List<Map<String, Object>>> result = new JsonResult<List<Map<String, Object>>>();
        try{
            String museumIdStr = (String) map.get("museumId");
            String objectId = (String) map.get("objectId");
            
            int museumId = Integer.parseInt(museumIdStr);
            
            // 从关系型数据库获取文物信息
            Product product = iProductService.findByProductId(museumId, objectId);
            
            String relicName = product != null ? product.getTitle() : "文物";
            
            // 构建实体ID: entity:artifact:{museum_id}:{object_id}
            String entityId = "entity:artifact:" + museumId + ":" + objectId;
            
            // 从Neo4j知识图谱查询关联关系（三元组）
            List<Map<String, Object>> knowledgeList = new ArrayList<>();
            boolean neo4jSuccess = false;
            
            try (Session session = neo4jDriver.session()) {
                String cypher = "MATCH (r:artifact {id: $entityId})-[rel]->(target) " +
                               "RETURN r.id as subject, type(rel) as predicate, " +
                               "coalesce(target.name, target.label, target.id) as object " +
                               "LIMIT 20";
                Result queryResult = session.run(cypher, org.neo4j.driver.Values.parameters("entityId", entityId));
                
                while (queryResult.hasNext()) {
                    org.neo4j.driver.Record record = queryResult.next();
                    Map<String, Object> triple = new java.util.HashMap<>();
                    triple.put("subject", record.get("subject").asString());
                    triple.put("predicate", record.get("predicate").asString());
                    triple.put("object", record.get("object").asString());
                    knowledgeList.add(triple);
                }
                neo4jSuccess = true;
            } catch (Exception neo4jEx) {
                // Neo4j连接或查询失败，记录日志但继续执行
                System.err.println("Neo4j query failed: " + neo4jEx.getMessage());
            }
            
            // 如果Neo4j没有数据（包括查询失败或返回空结果），返回基于MySQL数据的模拟三元组
            if (!neo4jSuccess || knowledgeList == null || knowledgeList.isEmpty()) {
                knowledgeList = new ArrayList<>();
                
                String type = product != null ? product.getType() : "文物";
                String material = product != null ? product.getMaterial() : "未知";
                String museum = product != null ? product.getMuseum() : "未知博物馆";
                String dynasty = product != null ? product.getDynasty() : "未知朝代";
                String culture = product != null ? product.getCulture() : "中国文化";
                
                Map<String, Object> knowledge1 = new java.util.HashMap<>();
                knowledge1.put("subject", relicName);
                knowledge1.put("predicate", "属于");
                knowledge1.put("object", type);
                knowledgeList.add(knowledge1);
                
                Map<String, Object> knowledge2 = new java.util.HashMap<>();
                knowledge2.put("subject", relicName);
                knowledge2.put("predicate", "材质为");
                knowledge2.put("object", material);
                knowledgeList.add(knowledge2);
                
                Map<String, Object> knowledge3 = new java.util.HashMap<>();
                knowledge3.put("subject", relicName);
                knowledge3.put("predicate", "收藏于");
                knowledge3.put("object", museum);
                knowledgeList.add(knowledge3);
                
                Map<String, Object> knowledge4 = new java.util.HashMap<>();
                knowledge4.put("subject", relicName);
                knowledge4.put("predicate", "创作于");
                knowledge4.put("object", dynasty);
                knowledgeList.add(knowledge4);
                
                Map<String, Object> knowledge5 = new java.util.HashMap<>();
                knowledge5.put("subject", relicName);
                knowledge5.put("predicate", "代表");
                knowledge5.put("object", culture);
                knowledgeList.add(knowledge5);
                
                Map<String, Object> knowledge6 = new java.util.HashMap<>();
                knowledge6.put("subject", relicName);
                knowledge6.put("predicate", "类别");
                knowledge6.put("object", type);
                knowledgeList.add(knowledge6);
                
                Map<String, Object> knowledge7 = new java.util.HashMap<>();
                knowledge7.put("subject", type);
                knowledge7.put("predicate", "包含");
                knowledge7.put("object", relicName);
                knowledgeList.add(knowledge7);
                
                Map<String, Object> knowledge8 = new java.util.HashMap<>();
                knowledge8.put("subject", museum);
                knowledge8.put("predicate", "收藏");
                knowledge8.put("object", relicName);
                knowledgeList.add(knowledge8);
            }
            
            result.setData(knowledgeList);
            result.setState(200);
            result.setMessage("获取知识成功");
        } catch(Exception e) {
            // 如果Neo4j连接失败，返回基于模拟数据的知识
            List<Map<String, Object>> knowledgeList = new ArrayList<>();
            
            Map<String, Object> knowledge1 = new java.util.HashMap<>();
            knowledge1.put("subject", "文物");
            knowledge1.put("predicate", "属于");
            knowledge1.put("object", "青铜器");
            knowledgeList.add(knowledge1);
            
            Map<String, Object> knowledge2 = new java.util.HashMap<>();
            knowledge2.put("subject", "文物");
            knowledge2.put("predicate", "材质为");
            knowledge2.put("object", "青铜");
            knowledgeList.add(knowledge2);
            
            Map<String, Object> knowledge3 = new java.util.HashMap<>();
            knowledge3.put("subject", "文物");
            knowledge3.put("predicate", "收藏于");
            knowledge3.put("object", "海外博物馆");
            knowledgeList.add(knowledge3);
            
            result.setData(knowledgeList);
            result.setState(200);
            result.setMessage("使用本地数据");
        }
        return result;
    }
    
    /**
     * 获取相关文物推荐
     */
    @RequestMapping("/related")
    public JsonResult<List<Cart>> getRelated(@RequestBody Map map) {
        JsonResult<List<Cart>> result = new JsonResult<List<Cart>>();
        try{
            String museumIdStr = (String) map.get("museumId");
            String dynasty = (String) map.get("dynasty");
            String artist = (String) map.get("artist");
            String culture = (String) map.get("culture");
            
            int museumId = Integer.parseInt(museumIdStr);
            
            List<Cart> relatedList = iCartService.SearchCommentView(
                museumId + "", 
                dynasty, 
                artist, 
                culture, 
                BigInteger.valueOf(museumId)
            );
            
            result.setData(relatedList);
            result.setState(200);
            result.setMessage("获取相关文物成功");
        } catch(Exception e) {
            result.setMessage("获取相关文物失败：" + e.getMessage());
            result.setState(6000);
        }
        return result;
    }
    
    /**
     * 分页查询文物列表（支持筛选和排序）
     * 请求参数：
     * - pageNum: 页码（默认1）
     * - pageSize: 每页数量（默认10）
     * - sortBy: 排序字段（title/dynasty/periodStartYear/crawlDate）
     * - sortOrder: 排序方向（asc/desc）
     * - title: 文物名称（模糊搜索）
     * - type: 文物类型
     * - dynasty: 朝代
     * - museumId: 博物馆ID
     * - museum: 博物馆名称（模糊搜索）
     * - material: 材质（模糊搜索）
     * - culture: 文化/地域标签（模糊搜索）
     * - artist: 作者（模糊搜索）
     */
    @RequestMapping("/list")
    public JsonResult<Map<String, Object>> getArtifactList(@RequestBody Map<String, Object> params) {
        JsonResult<Map<String, Object>> result = new JsonResult<Map<String, Object>>();
        try{
            // 获取分页参数
            Integer pageNum = params.get("pageNum") != null ? 
                Integer.parseInt(params.get("pageNum").toString()) : 1;
            Integer pageSize = params.get("pageSize") != null ? 
                Integer.parseInt(params.get("pageSize").toString()) : 10;
            
            // 设置默认排序
            if (params.get("sortBy") == null || params.get("sortBy").toString().isEmpty()) {
                params.put("sortBy", "crawlDate");
            }
            if (params.get("sortOrder") == null || params.get("sortOrder").toString().isEmpty()) {
                params.put("sortOrder", "desc");
            }
            
            // 查询数据
            List<Product> artifacts = iProductService.findByPage(params, pageNum, pageSize);
            Integer total = iProductService.countByParams(params);
            
            // 构建返回结果
            Map<String, Object> data = new java.util.HashMap<>();
            data.put("list", artifacts);
            data.put("total", total);
            data.put("pageNum", pageNum);
            data.put("pageSize", pageSize);
            data.put("totalPages", (total + pageSize - 1) / pageSize);
            
            result.setData(data);
            result.setState(200);
            result.setMessage("查询成功");
        } catch(Exception e) {
            result.setMessage("查询失败：" + e.getMessage());
            result.setState(6000);
        }
        return result;
    }
    
    /**
     * 获取筛选选项（类型、朝代、博物馆、材质）
     */
    @RequestMapping("/filters")
    public JsonResult<Map<String, List<String>>> getFilterOptions() {
        JsonResult<Map<String, List<String>>> result = new JsonResult<Map<String, List<String>>>();
        try{
            Map<String, List<String>> filters = new java.util.HashMap<>();
            filters.put("types", iProductService.getAllTypes());
            filters.put("dynasties", iProductService.getAllDynasties());
            filters.put("museums", iProductService.getAllMuseums());
            filters.put("materials", iProductService.getAllMaterials());
            
            result.setData(filters);
            result.setState(200);
            result.setMessage("获取筛选选项成功");
        } catch(Exception e) {
            result.setMessage("获取筛选选项失败：" + e.getMessage());
            result.setState(6000);
        }
        return result;
    }
    
    /**
     * 根据ID列表批量查询文物（用于对比功能）
     * 请求参数：
     * - ids: 文物ID列表，格式为 ["museumId_objectId", ...]
     */
    @RequestMapping("/batch")
    public JsonResult<List<Product>> getArtifactsByIds(@RequestBody Map<String, Object> params) {
        JsonResult<List<Product>> result = new JsonResult<List<Product>>();
        try{
            List<String> ids = (List<String>) params.get("ids");
            if (ids == null || ids.isEmpty()) {
                result.setData(new ArrayList<>());
                result.setState(200);
                result.setMessage("未选择文物");
                return result;
            }
            
            List<Product> artifacts = iProductService.findByIds(ids);
            result.setData(artifacts);
            result.setState(200);
            result.setMessage("查询成功");
        } catch(Exception e) {
            result.setMessage("查询失败：" + e.getMessage());
            result.setState(6000);
        }
        return result;
    }
    
    /**
     * 获取文物详情（简化版，用于列表展示）
     */
    @RequestMapping("/detail")
    public JsonResult<ProductView> getArtifactDetail(@RequestBody Map<String, Object> params) {
        JsonResult<ProductView> result = new JsonResult<ProductView>();
        try{
            Integer museumId = (Integer) params.get("museumId");
            String objectId = (String) params.get("objectId");
            String userid = (String) params.get("uid");
            
            Product artifact = iProductService.findByProductId(museumId, objectId);
            ProductView pv = new ProductView();
            BeanUtils.copyProperties(artifact, pv);
            
            if(userid != null && !userid.isEmpty()){
                Long userId = Long.parseLong(userid);
                Collect collect = collectService.findByUserIdAndArtifact(userId, museumId, objectId);
                if(collect != null) {
                    pv.setIf_collect(1);
                } else {
                    pv.setIf_collect(0);
                }
            } else {
                pv.setIf_collect(0);
            }
            
            result.setData(pv);
            result.setState(200);
            result.setMessage("查询成功");
        } catch(ProductNotFoundException e) {
            result.setState(6000);
            result.setMessage("文物不存在");
        } catch(Exception e) {
            result.setMessage("查询失败：" + e.getMessage());
            result.setState(6000);
        }
        return result;
    }

    /**
     * 获取文物的评论列表
     */
    @RequestMapping("/getComments")
    public JsonResult<List<CommentView>> getComments(@RequestBody Map<String, Object> params) {
        JsonResult<List<CommentView>> result = new JsonResult<>();
        try {
            Integer museumId = (Integer) params.get("museumId");
            String objectId = (String) params.get("objectId");
            
            List<CommentView> comments = iCommentService.getCommentsByArtifact(museumId, objectId);
            result.setData(comments);
            result.setState(200);
            result.setMessage("获取评论成功");
        } catch (Exception e) {
            result.setMessage("获取评论失败：" + e.getMessage());
            result.setState(6000);
        }
        return result;
    }

    /**
     * 添加评论
     */
    @RequestMapping("/addComment")
    public JsonResult<Long> addComment(@RequestBody Map<String, Object> params) {
        JsonResult<Long> result = new JsonResult<>();
        try {
            String userIdStr = (String) params.get("userId");
            Integer museumId = (Integer) params.get("museumId");
            String objectId = (String) params.get("objectId");
            String content = (String) params.get("content");
            
            Long userId = Long.parseLong(userIdStr);
            Long commentId = iCommentService.addComment(userId, museumId, objectId, content);
            
            result.setData(commentId);
            result.setState(200);
            result.setMessage("评论成功，等待审核");
        } catch (InsertException e) {
            result.setState(5000);
            result.setMessage(e.getMessage());
        } catch (Exception e) {
            result.setMessage("评论失败：" + e.getMessage());
            result.setState(6000);
        }
        return result;
    }

    @GetMapping("/keyword")
    public JsonResult<List<Product>> keywordSearch(@RequestParam String keyword) {
        JsonResult<List<Product>> result = new JsonResult<>();
        try {
            List<Product> products = iProductService.searchByKeyword(keyword);
            result.setData(products);
            result.setState(200);
            result.setMessage("查询成功");
        } catch (Exception e) {
            result.setState(6000);
            result.setMessage("查询失败：" + e.getMessage());
        }
        return result;
    }

    @PostMapping("/advanced")
    public JsonResult<Map<String, Object>> advancedSearch(@RequestBody ProductQueryDTO queryDTO) {
        JsonResult<Map<String, Object>> result = new JsonResult<>();
        try {
            Map<String, Object> data = iProductService.findByConditionsWithPage(queryDTO);
            result.setData(data);
            result.setState(200);
            result.setMessage("查询成功");
        } catch (Exception e) {
            result.setState(6000);
            result.setMessage("查询失败：" + e.getMessage());
        }
        return result;
    }

    @PostMapping("/multi-filter")
    public JsonResult<List<Product>> multiFilterSearch(@RequestBody ProductQueryDTO queryDTO) {
        JsonResult<List<Product>> result = new JsonResult<>();
        try {
            List<Product> products = iProductService.findByConditions(queryDTO);
            result.setData(products);
            result.setState(200);
            result.setMessage("查询成功，共找到 " + products.size() + " 条记录");
        } catch (Exception e) {
            result.setState(6000);
            result.setMessage("查询失败：" + e.getMessage());
        }
        return result;
    }

    @PostMapping("/export/csv")
    public ResponseEntity<byte[]> exportToCSV(@RequestBody ProductQueryDTO queryDTO) {
        try {
            String csvContent = iProductService.exportToCSV(queryDTO);
            byte[] csvBytes = csvContent.getBytes("UTF-8");
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("text/csv; charset=UTF-8"));
            headers.setContentDispositionFormData("attachment", "cultural_relics_export.csv");
            headers.setContentLength(csvBytes.length);
            return ResponseEntity.ok().headers(headers).body(csvBytes);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping("/export/json")
    public ResponseEntity<byte[]> exportToJSON(@RequestBody ProductQueryDTO queryDTO) {
        try {
            String jsonContent = iProductService.exportToJSON(queryDTO);
            byte[] jsonBytes = jsonContent.getBytes("UTF-8");
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setContentDispositionFormData("attachment", "cultural_relics_export.json");
            headers.setContentLength(jsonBytes.length);
            return ResponseEntity.ok().headers(headers).body(jsonBytes);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }
}
