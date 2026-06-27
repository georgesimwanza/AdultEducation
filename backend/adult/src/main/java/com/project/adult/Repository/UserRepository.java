package com.project.adult.Repository;

import com.project.adult.Model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User,Long> {
   Optional<User> findByEmail(String email);
   Optional<User> findByEmailIgnoreCase(String email);

    @Query("SELECT u FROM User u WHERE u.institution.id = :institutionId")
    List<User> findByInstitutionId(@Param("institutionId") Long institutionId);
}
