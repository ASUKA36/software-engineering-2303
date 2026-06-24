package com.mapper;

import com.entity.SensitiveWord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface SensitiveWordMapper {

    @Select("SELECT word, level FROM sensitive_words WHERE enabled = 1 ORDER BY word ASC")
    List<SensitiveWord> findAllEnabled();
}