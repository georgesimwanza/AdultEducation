package com.project.adult.Repository;

import com.project.adult.Model.UserContentProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserContentProgressRepository extends JpaRepository<UserContentProgress, Long> {

    Optional<UserContentProgress> findByUser_IdAndCourse_Id(Long userId, Long courseId);

    @Query("SELECT p FROM UserContentProgress p JOIN FETCH p.course WHERE p.user.id = :userId ORDER BY p.lastAccessed DESC")
    List<UserContentProgress> findByUserWithCourse(@Param("userId") Long userId);

    List<UserContentProgress> findByCourse_Id(Long courseId);
}
