package com.project.adult.Repository;

import com.project.adult.Model.AssignmentSubmission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface AssignmentSubmissionRepository extends JpaRepository<AssignmentSubmission, Long> {

    Optional<AssignmentSubmission> findByAssignment_IdAndLearner_Id(Long assignmentId, Long learnerId);

    @Query("SELECT s FROM AssignmentSubmission s JOIN FETCH s.learner WHERE s.assignment.id = :assignmentId ORDER BY s.submittedAt")
    List<AssignmentSubmission> findByAssignmentWithLearner(@Param("assignmentId") Long assignmentId);

    @Query("SELECT s FROM AssignmentSubmission s JOIN FETCH s.assignment a JOIN FETCH a.course WHERE s.learner.id = :learnerId")
    List<AssignmentSubmission> findByLearnerWithAssignment(@Param("learnerId") Long learnerId);

    @Query("SELECT s FROM AssignmentSubmission s JOIN FETCH s.assignment a WHERE a.course.id = :courseId")
    List<AssignmentSubmission> findByCourse(@Param("courseId") Long courseId);
}
