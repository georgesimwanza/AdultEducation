package com.project.adult.Repository;

import com.project.adult.Model.QuizSubmission;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface QuizSubmissionRepository extends JpaRepository<QuizSubmission, Long> {
    List<QuizSubmission> findByStudentEmail(String studentEmail);

    Optional<QuizSubmission> findByQuizIdAndStudentEmail(Long quizId, String studentEmail);
}