package com.project.adult.Repository;

import com.project.adult.Model.Programme;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface ProgrammeRepository extends JpaRepository<Programme,Long> {
    List<Programme> findByUpdatedAtAfter(LocalDateTime since);
}
