package com.project.adult.Repository;

import com.project.adult.Model.Enrollment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface EnrollmentRepository extends JpaRepository<Enrollment, Long> {

    Optional<Enrollment> findByUser_IdAndCourse_Id(Long userId, Long courseId);

    @Query("SELECT e FROM Enrollment e JOIN FETCH e.course WHERE e.user.id = :userId ORDER BY e.enrolledAt DESC")
    List<Enrollment> findByUserWithCourse(@Param("userId") Long userId);

    @Query("SELECT e FROM Enrollment e JOIN FETCH e.user WHERE e.course.id = :courseId AND e.status <> com.project.adult.Model.Enrollment.Status.DROPPED")
    List<Enrollment> findActiveByCourseWithUser(@Param("courseId") Long courseId);

    @Query("SELECT e FROM Enrollment e JOIN FETCH e.user u JOIN FETCH e.course " +
            "WHERE u.institution.id = :institutionId AND e.status <> com.project.adult.Model.Enrollment.Status.DROPPED")
    List<Enrollment> findActiveByInstitution(@Param("institutionId") Long institutionId);
}
