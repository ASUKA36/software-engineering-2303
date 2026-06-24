package com.service.Impl;

import com.entity.Product;
import com.entity.ProductQueryDTO;
import com.entity.StatisticsDTO;
import com.entity.TimelineDTO;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.mapper.FindImageMapper;
import com.mapper.ProductMapper;
import com.service.IProductService;
import com.service.exception.ProductNotFoundException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class ProductServiceImpl implements IProductService {
    @Autowired
    private ProductMapper productMapper;
    @Autowired
    private FindImageMapper findImageMapper;

    @Override
    public Product findByProductId(Integer museumId, String objectId){
        Product product = productMapper.findByProductId(museumId, objectId);
        if(product == null) {
            throw new ProductNotFoundException("该文物不存在");
        }
        if(product.getImageUrl() != null) {
            String[] address = product.getImageUrl().split(",");
            product.setImageUrl(address[0]);
        }
        return product;
    }

    @Override
    public List<Product> findAllProducts() {
        return productMapper.findAllProducts();
    }

    @Override
    public StatisticsDTO getStatistics() {
        StatisticsDTO dto = new StatisticsDTO();
        dto.setTotalAntiques(productMapper.countTotal());
        dto.setDynastyCount(productMapper.countDistinctDynasty());
        dto.setMuseumCount(productMapper.countDistinctMuseum());
        dto.setCategoryCount(productMapper.countDistinctType());

        dto.setCategoryDistribution(toNameValueList(productMapper.countByType()));
        dto.setDynastyDistribution(toNameValueList(productMapper.countByDynasty()));
        dto.setMuseumRanking(toNameValueList(productMapper.countByMuseum()));
        dto.setMaterialDistribution(toNameValueList(productMapper.countByMaterial()));
        dto.setRegionDistribution(toNameValueList(productMapper.countByLocation()));
        dto.setYearlyTrend(toNameValueList(productMapper.countByYear()));

        return dto;
    }

    private static final Map<String, int[]> DYNASTY_YEARS = new LinkedHashMap<>();
    static {
        DYNASTY_YEARS.put("Neolithic（新石器时代）", new int[]{-10000, -2000});
        DYNASTY_YEARS.put("Shang（商）", new int[]{-1600, -1046});
        DYNASTY_YEARS.put("Zhou（周）", new int[]{-1046, -256});
        DYNASTY_YEARS.put("Qin（秦）", new int[]{-221, -206});
        DYNASTY_YEARS.put("Han（汉）", new int[]{-206, 220});
        DYNASTY_YEARS.put("Western Han（西汉）", new int[]{-206, 25});
        DYNASTY_YEARS.put("Eastern Han（东汉）", new int[]{25, 220});
        DYNASTY_YEARS.put("Three Kingdoms（三国）", new int[]{220, 280});
        DYNASTY_YEARS.put("Jin（晋）", new int[]{265, 420});
        DYNASTY_YEARS.put("Jin（金）", new int[]{1115, 1234});
        DYNASTY_YEARS.put("Western Jin（西晋）", new int[]{265, 316});
        DYNASTY_YEARS.put("Eastern Jin（东晋）", new int[]{317, 420});
        DYNASTY_YEARS.put("Northern and Southern（南北朝）", new int[]{420, 589});
        DYNASTY_YEARS.put("Sui（隋）", new int[]{581, 618});
        DYNASTY_YEARS.put("Tang（唐）", new int[]{618, 907});
        DYNASTY_YEARS.put("Five Dynasties（五代）", new int[]{907, 960});
        DYNASTY_YEARS.put("Northern Song（北宋）", new int[]{960, 1127});
        DYNASTY_YEARS.put("Southern Song（南宋）", new int[]{1127, 1279});
        DYNASTY_YEARS.put("Yuan（元）", new int[]{1271, 1368});
        DYNASTY_YEARS.put("Ming（明）", new int[]{1368, 1644});
        DYNASTY_YEARS.put("Qing（清）", new int[]{1644, 1912});
        DYNASTY_YEARS.put("Republic（民国）", new int[]{1912, 1949});
        DYNASTY_YEARS.put("Shang Dynasty", new int[]{-1600, -1046});
        DYNASTY_YEARS.put("Zhou Dynasty", new int[]{-1046, -256});
        DYNASTY_YEARS.put("Qin Dynasty", new int[]{-221, -206});
        DYNASTY_YEARS.put("Han Dynasty", new int[]{-206, 220});
        DYNASTY_YEARS.put("Western Han Dynasty", new int[]{-206, 25});
        DYNASTY_YEARS.put("Eastern Han Dynasty", new int[]{25, 220});
        DYNASTY_YEARS.put("Three Kingdoms", new int[]{220, 280});
        DYNASTY_YEARS.put("Jin Dynasty", new int[]{265, 420});
        DYNASTY_YEARS.put("Northern and Southern Dynasties", new int[]{420, 589});
        DYNASTY_YEARS.put("Sui Dynasty", new int[]{581, 618});
        DYNASTY_YEARS.put("Tang Dynasty", new int[]{618, 907});
        DYNASTY_YEARS.put("Five Dynasties", new int[]{907, 960});
        DYNASTY_YEARS.put("Northern Song", new int[]{960, 1127});
        DYNASTY_YEARS.put("Southern Song", new int[]{1127, 1279});
        DYNASTY_YEARS.put("Yuan Dynasty", new int[]{1271, 1368});
        DYNASTY_YEARS.put("Ming Dynasty", new int[]{1368, 1644});
        DYNASTY_YEARS.put("Qing Dynasty", new int[]{1644, 1912});
        DYNASTY_YEARS.put("Republic period", new int[]{1912, 1949});
        DYNASTY_YEARS.put("Modern", new int[]{1949, 2025});
    }

    private static final Map<String, String> DYNASTY_CN = new LinkedHashMap<>();
    static {
        DYNASTY_CN.put("Neolithic（新石器时代）", "新石器时代");
        DYNASTY_CN.put("Shang（商）", "商朝");
        DYNASTY_CN.put("Zhou（周）", "周朝");
        DYNASTY_CN.put("Qin（秦）", "秦朝");
        DYNASTY_CN.put("Han（汉）", "汉朝");
        DYNASTY_CN.put("Western Han（西汉）", "西汉");
        DYNASTY_CN.put("Eastern Han（东汉）", "东汉");
        DYNASTY_CN.put("Three Kingdoms（三国）", "三国");
        DYNASTY_CN.put("Jin（晋）", "晋朝");
        DYNASTY_CN.put("Jin（金）", "金朝");
        DYNASTY_CN.put("Western Jin（西晋）", "西晋");
        DYNASTY_CN.put("Eastern Jin（东晋）", "东晋");
        DYNASTY_CN.put("Northern and Southern（南北朝）", "南北朝");
        DYNASTY_CN.put("Sui（隋）", "隋朝");
        DYNASTY_CN.put("Tang（唐）", "唐朝");
        DYNASTY_CN.put("Five Dynasties（五代）", "五代");
        DYNASTY_CN.put("Northern Song（北宋）", "北宋");
        DYNASTY_CN.put("Southern Song（南宋）", "南宋");
        DYNASTY_CN.put("Yuan（元）", "元朝");
        DYNASTY_CN.put("Ming（明）", "明朝");
        DYNASTY_CN.put("Qing（清）", "清朝");
        DYNASTY_CN.put("Republic（民国）", "民国");
        DYNASTY_CN.put("Shang Dynasty", "商朝");
        DYNASTY_CN.put("Zhou Dynasty", "周朝");
        DYNASTY_CN.put("Qin Dynasty", "秦朝");
        DYNASTY_CN.put("Han Dynasty", "汉朝");
        DYNASTY_CN.put("Western Han Dynasty", "西汉");
        DYNASTY_CN.put("Eastern Han Dynasty", "东汉");
        DYNASTY_CN.put("Three Kingdoms", "三国");
        DYNASTY_CN.put("Jin Dynasty", "晋朝");
        DYNASTY_CN.put("Northern and Southern Dynasties", "南北朝");
        DYNASTY_CN.put("Sui Dynasty", "隋朝");
        DYNASTY_CN.put("Tang Dynasty", "唐朝");
        DYNASTY_CN.put("Five Dynasties", "五代");
        DYNASTY_CN.put("Northern Song", "北宋");
        DYNASTY_CN.put("Southern Song", "南宋");
        DYNASTY_CN.put("Yuan Dynasty", "元朝");
        DYNASTY_CN.put("Ming Dynasty", "明朝");
        DYNASTY_CN.put("Qing Dynasty", "清朝");
        DYNASTY_CN.put("Republic period", "民国");
        DYNASTY_CN.put("Modern", "现代");
    }

    @Override
    public TimelineDTO getTimeline() {
        TimelineDTO dto = new TimelineDTO();
        dto.setTotalAntiques(productMapper.countTotal());
        dto.setPeriodCount(productMapper.countDistinctDynasty());
        dto.setMuseumCount(productMapper.countDistinctMuseum());

        List<Map<String, Object>> dynastyCounts = productMapper.countByDynasty();
        List<TimelineDTO.TimelineItem> items = new ArrayList<>();

        for (Map<String, Object> entry : dynastyCounts) {
            String dynasty = String.valueOf(entry.get("name"));
            Integer count = ((Number) entry.get("value")).intValue();

            String dynastyCn = DYNASTY_CN.getOrDefault(dynasty, dynasty);
            int[] years = DYNASTY_YEARS.getOrDefault(dynasty, new int[]{0, 0});

            TimelineDTO.TimelineItem item = new TimelineDTO.TimelineItem(
                dynastyCn, dynasty, count, years[0], years[1]
            );

            List<Product> products = productMapper.findByDynasty(dynasty);
            List<TimelineDTO.AntiqueBrief> antiques = new ArrayList<>();
            for (Product p : products) {
                String img = p.getImagePath();
                if (img == null || img.isEmpty()) {
                    img = p.getImageUrl();
                    if (img != null && img.contains(",")) {
                        img = img.split(",")[0];
                    }
                }
                antiques.add(new TimelineDTO.AntiqueBrief(
                    p.getObjectId(), p.getMuseumId(), p.getTitle(), p.getMuseum(), img
                ));
            }
            item.setAntiques(antiques);
            items.add(item);
        }

        items.sort(Comparator.comparingInt(a -> a.getStartYear() != null ? a.getStartYear() : 0));

        Integer noDynastyCount = productMapper.countNoDynasty();
        if (noDynastyCount != null && noDynastyCount > 0) {
            List<Product> noDynastyProducts = productMapper.findNoDynasty();
            List<TimelineDTO.AntiqueBrief> noDynastyAntiques = new ArrayList<>();
            for (Product p : noDynastyProducts) {
                String img = p.getImageUrl();
                if (img != null && img.contains(",")) {
                    img = img.split(",")[0];
                }
                if (img == null || img.isEmpty()) {
                    img = p.getImagePath();
                }
                noDynastyAntiques.add(new TimelineDTO.AntiqueBrief(
                    p.getObjectId(), p.getMuseumId(), p.getTitle(), p.getMuseum(), img
                ));
            }
            TimelineDTO.TimelineItem unknownItem = new TimelineDTO.TimelineItem(
                "未知朝代", "", noDynastyCount, 0, 0
            );
            unknownItem.setAntiques(noDynastyAntiques);
            items.add(unknownItem);
        }

        dto.setItems(items);
        return dto;
    }

    private List<StatisticsDTO.NameValueItem> toNameValueList(List<Map<String, Object>> mapList) {
        List<StatisticsDTO.NameValueItem> result = new ArrayList<>();
        if (mapList == null) return result;
        for (Map<String, Object> entry : mapList) {
            String name = String.valueOf(entry.get("name"));
            Integer value = ((Number) entry.get("value")).intValue();
            result.add(new StatisticsDTO.NameValueItem(name, value));
        }
        return result;
    }

    @Override
    public List<Product> findByPage(Map<String, Object> params, Integer pageNum, Integer pageSize) {
        Integer offset = (pageNum - 1) * pageSize;
        List<Product> products = productMapper.findByPage(params, offset, pageSize);
        for (Product product : products) {
            if (product.getImageUrl() != null) {
                String[] address = product.getImageUrl().split(",");
                product.setImageUrl(address[0]);
            }
        }
        return products;
    }

    @Override
    public Integer countByParams(Map<String, Object> params) {
        return productMapper.countByParams(params);
    }

    @Override
    public List<Product> findByIds(List<String> ids) {
        List<Product> products = productMapper.findByIds(ids);
        for (Product product : products) {
            if (product.getImageUrl() != null) {
                String[] address = product.getImageUrl().split(",");
                product.setImageUrl(address[0]);
            }
        }
        return products;
    }

    @Override
    public List<String> getAllTypes() {
        return productMapper.getAllTypes();
    }

    @Override
    public List<String> getAllDynasties() {
        return productMapper.getAllDynasties();
    }

    @Override
    public List<String> getAllMuseums() {
        return productMapper.getAllMuseums();
    }

    @Override
    public List<String> getAllMaterials() {
        return productMapper.getAllMaterials();
    }

    @Override
    public List<Product> findByConditions(ProductQueryDTO queryDTO) {
        List<Product> products = productMapper.findByConditions(queryDTO);
        for (Product product : products) {
            if (product.getImageUrl() != null) {
                String[] address = product.getImageUrl().split(",");
                product.setImageUrl(address[0]);
            }
        }
        return products;
    }

    @Override
    public Map<String, Object> findByConditionsWithPage(ProductQueryDTO queryDTO) {
        Map<String, Object> result = new HashMap<>();
        Integer pageNum = queryDTO.getPageNum() != null ? queryDTO.getPageNum() : 1;
        Integer pageSize = queryDTO.getPageSize() != null ? queryDTO.getPageSize() : 10;
        Integer offset = (pageNum - 1) * pageSize;
        List<Product> products = productMapper.findByConditionsWithPage(queryDTO, offset, pageSize);
        Integer total = productMapper.countByConditions(queryDTO);
        for (Product product : products) {
            if (product.getImageUrl() != null) {
                String[] address = product.getImageUrl().split(",");
                product.setImageUrl(address[0]);
            }
        }
        result.put("list", products);
        result.put("total", total);
        result.put("pageNum", pageNum);
        result.put("pageSize", pageSize);
        result.put("totalPages", (int) Math.ceil((double) total / pageSize));
        return result;
    }

    @Override
    public List<Product> searchByKeyword(String keyword) {
        List<Product> products = productMapper.searchByKeyword(keyword);
        for (Product product : products) {
            if (product.getImageUrl() != null) {
                String[] address = product.getImageUrl().split(",");
                product.setImageUrl(address[0]);
            }
        }
        return products;
    }

    @Override
    public String exportToCSV(ProductQueryDTO queryDTO) {
        List<Product> products = productMapper.findByConditions(queryDTO);
        StringBuilder sb = new StringBuilder();
        sb.append("museumId,objectId,title,artist,dynasty,type,material,museum\n");
        for (Product p : products) {
            sb.append(escapeCsv(String.valueOf(p.getMuseumId()))).append(",");
            sb.append(escapeCsv(p.getObjectId())).append(",");
            sb.append(escapeCsv(p.getTitle())).append(",");
            sb.append(escapeCsv(p.getArtist())).append(",");
            sb.append(escapeCsv(p.getDynasty())).append(",");
            sb.append(escapeCsv(p.getType())).append(",");
            sb.append(escapeCsv(p.getMaterial())).append(",");
            sb.append(escapeCsv(p.getMuseum())).append("\n");
        }
        return sb.toString();
    }

    @Override
    public String exportToJSON(ProductQueryDTO queryDTO) {
        try {
            List<Product> products = productMapper.findByConditions(queryDTO);
            ObjectMapper mapper = new ObjectMapper();
            mapper.enable(SerializationFeature.INDENT_OUTPUT);
            return mapper.writeValueAsString(products);
        } catch (Exception e) {
            return "[]";
        }
    }

    private String escapeCsv(String s) {
        if (s == null) return "";
        if (s.contains(",") || s.contains("\"") || s.contains("\n")) {
            return "\"" + s.replace("\"", "\"\"") + "\"";
        }
        return s;
    }
}
