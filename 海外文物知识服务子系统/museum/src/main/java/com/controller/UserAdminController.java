package com.controller;

import com.entity.CommentView;
import com.entity.CollectView;
import com.service.CollectService;
import com.service.ICommentService;
import com.service.IUserService;
import com.service.exception.*;
import com.util.JsonResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("user_admin")
public class UserAdminController {
    @Autowired
    private IUserService iUserService;

    @Autowired
    private ICommentService iCommentService;

    @Autowired
    private CollectService collectService;

    @RequestMapping("/update")
    public JsonResult<Integer> update(@RequestBody Map map) {
        JsonResult<Integer> result = new JsonResult<>();
        try {
            String a = (String) map.get("id");
            int user_id = Integer.parseInt(a);
            String old_pass = (String) map.get("oldPassword");
            String user_password = (String) map.get("newPassword");
            String user_name = (String) map.get("name");
            String s = (String) map.get("sex");
            int sex = Integer.parseInt(s);
            String user_tel = (String) map.get("tel");
            int row = iUserService.up(Long.valueOf(user_id), old_pass, user_password, user_name, null, sex, null, user_tel, null);
            result.setData(row);
            result.setState(200);
            result.setMessage("更新成功！");
        } catch (PasswordNotMatchException e) {
            result.setState(6000);
            result.setMessage("原密码输入错误！");
        } catch (UsernameCompetedException e) {
            result.setState(5000);
            result.setMessage("用户名已存在，请重新修改！");
        } catch (ServiceException e) {
            result.setState(4000);
            result.setMessage("更新失败！");
        }
        return result;
    }

    /**
     * 获取用户的评论列表
     */
    @RequestMapping("/comment")
    public JsonResult<List<CommentView>> getComments(@RequestBody Map map) {
        String userIdStr = (String) map.get("userId");
        if (userIdStr == null || userIdStr.isEmpty()) {
            userIdStr = (String) map.get("username");
        }
        Long userId = Long.parseLong(userIdStr);
        JsonResult<List<CommentView>> result = new JsonResult<>();
        List<CommentView> comments = iCommentService.getCommentsByUser(userId);
        result.setData(comments);
        result.setState(200);
        result.setMessage("获取评论列表成功");
        return result;
    }

    @RequestMapping("/collect")
    public JsonResult<List<CollectView>> findCollect(@RequestBody Map map) {
        String userid = (String) map.get("id");
        Long userId = Long.parseLong(userid);
        JsonResult<List<CollectView>> result = new JsonResult<>();
        List<CollectView> ans = collectService.collectionfromuid(userId);
        result.setState(200);
        result.setData(ans);
        result.setMessage("以下为收藏文物：");
        return result;
    }

    @RequestMapping("/deleteCollect")
    public JsonResult<Integer> deleteCollect(@RequestBody Map map) {
        JsonResult<Integer> result = new JsonResult<>();
        try {
            String userid = (String) map.get("userId");
            String museumIdStr = (String) map.get("museumId");
            String objectId = (String) map.get("objectId");

            Long userId = Long.parseLong(userid);
            Integer museumId = Integer.parseInt(museumIdStr);

            result.setData(collectService.removecollection(
                    collectService.findByUserIdAndArtifact(userId, museumId, objectId).getFavoriteId()
            ));
            result.setState(200);
            result.setMessage("取消收藏成功");
        } catch (DeleteLoss e) {
            result.setState(4000);
            result.setMessage("收藏文物未找到");
        } catch (Exception e) {
            result.setState(5000);
            result.setMessage("取消收藏失败：" + e.getMessage());
        }
        return result;
    }

    /**
     * 删除评论
     */
    @RequestMapping("/deleteComment")
    public JsonResult<Integer> deleteComment(@RequestBody Map map) {
        JsonResult<Integer> result = new JsonResult<>();
        try {
            Long commentId;
            Object commentIdObj = map.get("commentId");
            if (commentIdObj == null) {
                commentIdObj = map.get("cid");
            }
            if (commentIdObj instanceof Integer) {
                commentId = ((Integer) commentIdObj).longValue();
            } else {
                commentId = Long.parseLong((String) commentIdObj);
            }
            iCommentService.softDeleteComment(commentId);
            result.setData(1);
            result.setMessage("删除评论成功");
            result.setState(200);
        } catch (DeleteLoss e) {
            result.setState(4000);
            result.setMessage("评论未找到");
        } catch (DeleteException e) {
            result.setState(6000);
            result.setMessage("删除评论失败");
        } catch (Exception e) {
            result.setState(5000);
            result.setMessage("删除评论失败：" + e.getMessage());
        }
        return result;
    }
}
