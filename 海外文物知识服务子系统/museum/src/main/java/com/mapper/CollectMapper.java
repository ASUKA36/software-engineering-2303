package com.mapper;

import com.entity.Collect;
import com.entity.CollectView;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
@Mapper
public interface CollectMapper {
    Integer insert(Collect collect);

    Integer delete(Long favoriteId);

    Collect findById(Long favoriteId);

    Collect findByUserIdAndArtifact(@Param("userId") Long userId,
                                   @Param("museumId") Integer museumId,
                                   @Param("objectId") String objectId);

    List<CollectView> findByUserId(Long userId);

    List<Collect> findByMuseumIdAndObjectId(@Param("museumId") Integer museumId,
                                            @Param("objectId") String objectId);
}
