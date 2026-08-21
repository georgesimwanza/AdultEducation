package com.project.adult.Service;

import com.project.adult.Model.Announcement;
import com.project.adult.Model.Institution;
import com.project.adult.Model.Programme;
import com.project.adult.Repository.AnnouncementRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.NoSuchElementException;

/**
 * Service layer for managing {@link Announcement} entities.
 * <p>
 * Provides CRUD operations for announcements, as well as lookups scoped
 * to a specific {@link Programme} and/or {@link Institution}.
 */
@Service
@RequiredArgsConstructor
public class AnnouncementService {

    private final AnnouncementRepository announcementRepository;

    /**
     * Retrieves all announcements in the system.
     *
     * @return a list of all announcements
     */
    public List<Announcement> getAll() {
        return announcementRepository.findAll();
    }

    /**
     * Retrieves a single announcement by its identifier.
     *
     * @param id the announcement id
     * @return the matching announcement
     * @throws NoSuchElementException if no announcement exists with the given id
     */
    public Announcement getById(int id) {
        return announcementRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Announcement not found: " + id));
    }

    /**
     * Retrieves all announcements belonging to a specific programme.
     *
     * @param programmeId the id of the programme
     * @return a list of announcements for the given programme
     */
    public List<Announcement> getByProgramme(int programmeId) {
        return announcementRepository.findByProgramme_Id(programmeId);
    }

    /**
     * Retrieves all announcements belonging to a specific institution.
     *
     * @param institutionId the id of the institution
     * @return a list of announcements for the given institution
     */
    public List<Announcement> getByInstitution(int institutionId) {
        return announcementRepository.findByInstitution_Id(institutionId);
    }

    /**
     * Retrieves announcements matching a given institution and/or programme.
     *
     * @param institutionId the id of the institution
     * @param programmeId   the id of the programme
     * @return a list of announcements matching the given institution and/or programme
     */
    public List<Announcement> getByInstitutionAndProgramme(int institutionId, int programmeId) {
        return announcementRepository.getByInstitutionAndOrProgramme(institutionId, programmeId);
    }

    /**
     * Creates and persists a new announcement.
     *
     * @param announcement the announcement to create
     * @return the saved announcement, including its generated id
     */
    public Announcement create(Announcement announcement) {
        return announcementRepository.save(announcement);
    }

    /**
     * Updates an existing announcement's title, content, programme, and institution.
     *
     * @param id      the id of the announcement to update
     * @param updated an announcement instance containing the new field values
     * @return the updated and saved announcement
     * @throws NoSuchElementException if no announcement exists with the given id
     */
    public Announcement update(int id, Announcement updated) {
        Announcement existing = getById(id);
        existing.setTitle(updated.getTitle());
        existing.setContent(updated.getContent());
        existing.setProgramme(updated.getProgramme());
        existing.setInstitution(updated.getInstitution());
        return announcementRepository.save(existing);
    }

    /**
     * Deletes an announcement by its identifier.
     *
     * @param id the id of the announcement to delete
     * @throws NoSuchElementException if no announcement exists with the given id
     */
    public void delete(int id) {
        if (!announcementRepository.existsById(id)) {
            throw new NoSuchElementException("Announcement not found: " + id);
        }
        announcementRepository.deleteById(id);
    }

    /**
     * Builds and saves a new announcement from raw request fields, linking it
     * to a programme and institution by id reference only (no lookup is performed).
     *
     * @param title         the announcement title
     * @param content       the announcement body content
     * @param programmeId   the id of the programme to associate with the announcement
     * @param institutionId the id of the institution to associate with the announcement
     * @return the saved announcement
     */
    public Announcement createFromRequest(String title, String content, Long programmeId, Long institutionId) {
        Announcement announcement = new Announcement();
        announcement.setTitle(title);
        announcement.setContent(content);
        Programme programme = new Programme();
        programme.setId(programmeId);
        announcement.setProgramme(programme);
        Institution institution = new Institution();
        institution.setId(institutionId);
        announcement.setInstitution(institution);
        return announcementRepository.save(announcement);
    }
}