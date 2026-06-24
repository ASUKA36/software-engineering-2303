package com.service.Impl;

import com.entity.Collect;
import com.entity.CollectView;
import com.mapper.CollectMapper;
import com.service.CollectService;
import com.service.exception.CollectduplicateException;
import com.service.exception.DeleteLoss;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CollectServicelmpl implements CollectService {
    @Autowired
    private CollectMapper collectmapper;

    private String stripHtml(String s) {
        if (s == null) return null;
        return s.replaceAll("<[^>]+>", "");
    }

    @Override
    public Integer addcollection(Collect collect) {
        Collect result = collectmapper.findByUserIdAndArtifact(
                collect.getUserId(),
                collect.getMuseumId(),
                collect.getObjectId()
        );
        if (result != null) {
            throw new CollectduplicateException("请勿重复添加");
        }
        return collectmapper.insert(collect);
    }

    @Override
    public Integer removecollection(Long favoriteId) {
        Collect result = collectmapper.findById(favoriteId);
        if (result == null) {
            throw new DeleteLoss("取消收藏信息未找到");
        }
        return collectmapper.delete(favoriteId);
    }

    @Override
    public List<CollectView> collectionfromuid(Long userId) {
        List<CollectView> list = collectmapper.findByUserId(userId);
        for (CollectView cv : list) {
            cv.setObjectName(stripHtml(cv.getObjectName()));
        }
        return list;
    }

    @Override
    public Collect findByUserIdAndArtifact(Long userId, Integer museumId, String objectId) {
        return collectmapper.findByUserIdAndArtifact(userId, museumId, objectId);
    }
}
