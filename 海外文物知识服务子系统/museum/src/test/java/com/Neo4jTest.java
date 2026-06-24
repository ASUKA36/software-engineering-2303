//package com;
//
//import com.entity.Product_neo4j;
//import com.repository.ProductRepository;
//import org.junit.Test;
//import org.junit.runner.RunWith;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.autoconfigure.domain.EntityScan;
//import org.springframework.boot.test.context.SpringBootTest;
//import org.springframework.data.neo4j.repository.config.EnableNeo4jRepositories;
//import org.springframework.test.context.junit4.SpringRunner;
//
//import java.util.Optional;
//
//@SpringBootTest
//@RunWith(SpringRunner.class)
//public class Neo4jTest {
//    @Autowired
//     ProductRepository productRepository;
//    @Test
//    public void test_correct(){
//       Optional<Product_neo4j> byId =  productRepository.findById(18L);
//       byId.orElse(null);
//
//    }
//}
