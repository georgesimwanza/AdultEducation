package com.project.adult.Repository;

import com.project.adult.Model.ProgrammeCourse;
import com.project.adult.Model.ProgrammeCourseId;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProgrammeCourseRepository extends JpaRepository<ProgrammeCourse, ProgrammeCourseId> {
}
