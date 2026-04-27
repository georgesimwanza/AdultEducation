package com.project.adult.Repository;

import com.project.adult.Model.Content;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;


public interface ContentRepository extends JpaRepository<Content,Long> {
    @Query("SELECT C FROM Content C WHERE C.course.id = :id")
    List<Content> findContentbySubjectId(@Param("id") Long id);
}
