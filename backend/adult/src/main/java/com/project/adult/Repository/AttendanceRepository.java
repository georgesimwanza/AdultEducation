package com.project.adult.Repository;

import com.project.adult.Model.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface AttendanceRepository extends JpaRepository<Attendance, Long> {

    Optional<Attendance> findByCourse_IdAndLearner_IdAndSessionDate(Long courseId, Long learnerId, LocalDate date);

    @Query("SELECT a FROM Attendance a JOIN FETCH a.learner WHERE a.course.id = :courseId AND a.sessionDate = :date")
    List<Attendance> findByCourseAndDate(@Param("courseId") Long courseId, @Param("date") LocalDate date);

    @Query("SELECT a FROM Attendance a JOIN FETCH a.course WHERE a.learner.id = :learnerId ORDER BY a.sessionDate DESC")
    List<Attendance> findByLearnerWithCourse(@Param("learnerId") Long learnerId);

    List<Attendance> findByCourse_Id(Long courseId);
}
