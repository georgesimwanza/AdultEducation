package com.project.adult.Repository;

import com.project.adult.Model.Assignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

public interface AssignmentRepository extends JpaRepository<Assignment, Long> {

    @Query("SELECT a FROM Assignment a JOIN FETCH a.course WHERE a.course.id IN :courseIds ORDER BY a.dueDate")
    List<Assignment> findByCourseIds(@Param("courseIds") Collection<Long> courseIds);

    @Query("SELECT a FROM Assignment a JOIN FETCH a.course WHERE a.institution.id = :institutionId ORDER BY a.dueDate DESC")
    List<Assignment> findByInstitution(@Param("institutionId") Long institutionId);

    @Query("SELECT a FROM Assignment a JOIN FETCH a.course WHERE a.reminderSent = false AND a.dueDate BETWEEN :from AND :to")
    List<Assignment> findDueBetweenWithoutReminder(@Param("from") LocalDateTime from, @Param("to") LocalDateTime to);
}
