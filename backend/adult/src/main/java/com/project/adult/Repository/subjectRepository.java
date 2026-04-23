package com.project.adult.Repository;

import com.project.adult.Model.Course;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface subjectRepository extends JpaRepository<Course,Long> {
    @Query("SELECT pc.course FROM ProgrammeCourse pc WHERE pc.programme.id = :programmeId")
    List<Course> findCoursesByProgrammeId(@Param("programmeId") Long programmeId);
}
