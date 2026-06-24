package com.service;

import com.entity.Collect;
import com.entity.CollectView;

import java.util.List;

public interface CollectService {
    Integer addcollection(Collect collect);

    Integer removecollection(Long favoriteId);

    List<CollectView> collectionfromuid(Long userId);

    Collect findByUserIdAndArtifact(Long userId, Integer museumId, String objectId);
}
