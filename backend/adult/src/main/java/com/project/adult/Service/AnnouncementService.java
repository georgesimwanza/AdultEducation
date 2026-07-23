package com.project.adult.Service;

import com.project.adult.Model.Announcement;
import com.project.adult.Model.Institution;
import com.project.adult.Model.Programme;
import com.project.adult.Repository.AnnouncementRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.NoSuchElementException;

@Service
@RequiredArgsConstructor
public class AnnouncementService {

    private final AnnouncementRepository announcementRepository;

    public List<Announcement> getAll() {
        return announcementRepository.findAll();
    }

    public Announcement getById(int id) {
        return announcementRepository.findById(id)
                .orElseThrow(() -> new NoSuchElementException("Announcement not found: " + id));
    }

    public List<Announcement> getByProgramme(int programmeId) {
        return announcementRepository.findByProgramme_Id(programmeId);
    }

    public List<Announcement> getByInstitution(int institutionId) {
        return announcementRepository.findByInstitution_Id(institutionId);
    }

    public List<Announcement> getByInstitutionAndProgramme(int institutionId, int programmeId) {
        return announcementRepository.getByInstitutionAndOrProgramme(institutionId, programmeId);
    }

    public Announcement create(Announcement announcement) {
        return announcementRepository.save(announcement);
    }

    public Announcement update(int id, Announcement updated) {
        Announcement existing = getById(id);
        existing.setTitle(updated.getTitle());
        existing.setContent(updated.getContent());
        existing.setProgramme(updated.getProgramme());
        existing.setInstitution(updated.getInstitution());
        return announcementRepository.save(existing);
    }

    public void delete(int id) {
        if (!announcementRepository.existsById(id)) {
            throw new NoSuchElementException("Announcement not found: " + id);
        }
        announcementRepository.deleteById(id);
    }
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