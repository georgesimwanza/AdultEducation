package com.project.adult.Repository;

import com.project.adult.Model.ContentView;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ContentViewRepository extends JpaRepository<ContentView, Long> {

    Optional<ContentView> findByUser_IdAndContent_Id(Long userId, Long contentId);

    long countByUser_IdAndCourseId(Long userId, Long courseId);

    List<ContentView> findByUser_IdAndCourseId(Long userId, Long courseId);
}
