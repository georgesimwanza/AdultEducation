package com.project.adult.Repository;

import com.project.adult.Model.Quiz;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface QuizRepository extends JpaRepository<Quiz, Long> {
    List<Quiz> findByCourse_IdAndInstitution_Id(Long courseId, Long institutionId);
    List<Quiz> findByCourse_Id(Long courseId);
    List<Quiz> findByInstitution_Id(Long institutionId);
    List<Quiz> findByProgramme_IdAndCourse_IdAndInstitution_Id(Long programmeId, Long courseId, Long institutionId);
    List<Quiz> findByProgramme_Id(Long programmeId);

}
