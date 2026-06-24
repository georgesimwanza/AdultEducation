package com.project.adult.Repository;

import com.project.adult.Model.Institution;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InstitutionRepository extends JpaRepository<Institution,Long> {
    boolean existsByName(String name);
}
