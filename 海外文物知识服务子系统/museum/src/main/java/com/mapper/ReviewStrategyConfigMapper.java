package com.mapper;

import com.entity.ReviewStrategyConfig;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface ReviewStrategyConfigMapper {

    @Select("SELECT low_risk_max_score, medium_risk_max_score, low_risk_action, medium_risk_action, high_risk_action FROM review_strategy_config WHERE id = 1")
    ReviewStrategyConfig findById();
}