package com.project.adult.Repository;

import com.project.adult.Model.Quiz;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface QuizRepository extends JpaRepository<Quiz, Long> {
    List<Quiz> findBySubjectIdAndInstitutionId(Long subjectId, Long institutionId);
    List<Quiz> findBySubjectId(Long subjectId);
    List<Quiz> findByInstitutionId(Long institutionId);
}
