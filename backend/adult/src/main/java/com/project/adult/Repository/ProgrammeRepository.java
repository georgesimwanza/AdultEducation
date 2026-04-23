package com.project.adult.Repository;

import com.project.adult.Model.Programme;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProgrammeRepository extends JpaRepository<Programme,Long> {
}
