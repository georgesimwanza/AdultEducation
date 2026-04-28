package com.project.adult.Repository;

import com.project.adult.Model.Schedule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ScheduleRepository extends JpaRepository<Schedule,Long> {
    List<Schedule> findByUserEmail(String userEmail);
}
