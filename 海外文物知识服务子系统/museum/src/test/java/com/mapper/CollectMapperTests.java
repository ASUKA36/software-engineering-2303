package com.mapper;


import com.entity.Collect;
import com.entity.CollectView;
import com.service.CollectService;
import com.service.exception.ServiceException;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import java.util.List;

@RunWith(SpringRunner.class)
@SpringBootTest
public class CollectMapperTests {
    @Autowired
    private CollectMapper collectmapper;
    @Autowired
    private CollectService collectservice;

    @Test
    public void addcollection(){
        try
        {
            Collect collect = new Collect();
            collect.setMuseumId(1);
            collect.setObjectId("test-object-001");
            collect.setUserId(1L);
            collectservice.addcollection(collect);
        }
        catch(ServiceException e){
            System.out.println("收藏失败！"+e.getClass().getSimpleName());
            System.out.println(e.getMessage());
        }
    }

    @Test
    public void delete(){
        try{
            collectservice.removecollection(1L);
        }
        catch(ServiceException e){
            System.out.println("删除失败！"+e.getClass().getSimpleName());
            System.out.println(e.getMessage());
        }
    }

    @Test
    public void view(){
        try{
            List<CollectView> result=collectservice.collectionfromuid(1L);
            for(int i=0;i<result.size();i++){
                System.out.println(result.get(i).getFavoriteId()+" "+
                        result.get(i).getObjectId()+" "+
                        result.get(i).getUserId()+" "+
                        result.get(i).getUsername()+" "+
                        result.get(i).getObjectName());
            }
        }
        catch(ServiceException e){
            System.out.println("查找失败！"+e.getClass().getSimpleName());
            System.out.println(e.getMessage());
        }
    }

    @Test
    public void test_mapper(){
        Collect collect;
        collect = collectmapper.findByUserIdAndArtifact(1L, 1, "test-object-001");
        System.out.println(collect.toString());

    }

    @Test
    public void findByUid_Rid(){
        Collect collect = collectservice.findByUserIdAndArtifact(1L, 1, "test-object-001");
        if(collect==null) System.out.println("未收藏");
        else System.out.println("已收藏");
    }
}
