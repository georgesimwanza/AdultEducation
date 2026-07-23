package com.project.adult.Repository;

import com.project.adult.Model.Announcement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface AnnouncementRepository extends JpaRepository<Announcement, Integer> {

    List<Announcement> findByProgramme_Id(Integer programmeId);

    List<Announcement> findByInstitution_Id(Integer institutionId);

    @Query("SELECT a FROM Announcement a WHERE a.programme.id = :programmeId OR a.institution.id = :institutionId")
    List<Announcement> findRelevantAnnouncements(@Param("programmeId") Integer programmeId,
                                                 @Param("institutionId") Integer institutionId);
    @Query("SELECT a FROM Announcement a WHERE " +
            "(:institutionId IS NULL OR a.institution.id = :institutionId) AND " +
            "(:programmeId IS NULL OR a.programme.id = :programmeId)")
    List<Announcement> getByInstitutionAndOrProgramme(
            @Param("institutionId") Integer institutionId,
            @Param("programmeId") Integer programmeId);
}