package com.mapper;
import com.entity.Comment;
import com.entity.CommentView;
import com.service.ICommentService;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

import java.util.ArrayList;
import java.util.List;

@RunWith(SpringRunner.class)
@SpringBootTest
public class CommentMapperTests {
    @Autowired
    private CommentMapper commentMapper;
    @Autowired
    private ICommentService icommentservice;
    
    @Test
    public void insert(){
        Comment comment = new Comment();
        comment.setUserId(1L);
        comment.setMuseumId(1);
        comment.setObjectId("test001");
        comment.setContent("6666ya");
        commentMapper.insert(comment);
    }
    
    @Test
    public void findByUidandRid(){
        List<CommentView> result;
        result = commentMapper.findByUserIdAndArtifact(1L, 1, "test001");
        for(int i=0;i<result.size();i++)
            System.out.println(result.get(i).getUsername()+"  "+result.get(i).getObjectName()+" "+result.get(i).getContent()+" "+result.get(i).getCreatedAt());
    }
    
    @Test
    public void find(){
        List<CommentView> result;
        result = commentMapper.findByArtifact(1, "test001");
        for(int i=0;i<result.size();i++)
            System.out.println(result.get(i).getCommentId());
        result = commentMapper.findByUserId(1L);
        for(int i=0;i<result.size();i++)
            System.out.println(result.get(i).getCommentId());
    }
    
    @Test
    public void find_by_cid(){
        Comment comment;
        comment = commentMapper.findByCid(1L);
        System.out.println(comment.toString()+ comment.getCreatedAt() + comment.getUpdatedAt());
    }
    
    @Test
    public void view(){
        ArrayList<CommentView> r1 = (ArrayList<CommentView>) icommentservice.getCommentsByArtifact(1, "test001");
        ArrayList<CommentView> r2 = (ArrayList<CommentView>) icommentservice.getCommentsByUserAndArtifact(1L, 1, "test001");
        ArrayList<CommentView> r3 = (ArrayList<CommentView>) icommentservice.getCommentsByUser(1L);
        for(int i=0;i<r1.size();i++){
            System.out.println(r1.get(i).getContent());
        }
        for(int i=0;i<r2.size();i++){
            System.out.println(r2.get(i).getContent());
        }
        for(int i=0;i<r3.size();i++){
            System.out.println(r3.get(i).getContent());
        }
    }
    
    @Test
    public void delete(){
        icommentservice.softDeleteComment(4L);
        System.out.println("delete success");
    }
}
