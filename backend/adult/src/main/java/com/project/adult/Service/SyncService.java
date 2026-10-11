package com.project.adult.Service;

import com.project.adult.DTO.ContentDTO;
import com.project.adult.DTO.QuizDto;
import com.project.adult.DTO.SubjectDTO;
import com.project.adult.Model.Announcement;
import com.project.adult.Model.Course;
import com.project.adult.Model.Programme;
import com.project.adult.Model.Quiz;
import com.project.adult.Repository.AnnouncementRepository;
import com.project.adult.Repository.ContentRepository;
import com.project.adult.Repository.ProgrammeRepository;
import com.project.adult.Repository.QuizRepository;
import com.project.adult.Repository.subjectRepository;
import com.project.adult.Utilities.QuizMapper;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Service layer supporting offline/incremental sync for the mobile client.
 * <p>
 * Each {@code getSynced*} method returns either the full dataset (when
 * {@code since} is {@code null}) or only records updated after the given
 * epoch-millisecond timestamp, so the client can pull incremental changes.
 */
@Service
@Transactional
public class SyncService {
    private final subjectRepository subjectRepository;
    private final ContentRepository contentRepository;
    private final ProgrammeRepository programmeRepository;
    private final AnnouncementRepository announcementRepository;
    private final QuizRepository quizRepository;

    /**
     * Constructs the service with its required repositories.
     *
     * @param subjectRepository      repository for persisting and querying subjects/courses
     * @param contentRepository      repository for persisting and querying content
     * @param programmeRepository    repository for persisting and querying programmes
     * @param announcementRepository repository for persisting and querying announcements
     * @param quizRepository         repository for persisting and querying quizzes
     */
    public SyncService(subjectRepository subjectRepository, ContentRepository contentRepository, ProgrammeRepository programmeRepository, AnnouncementRepository announcementRepository, QuizRepository quizRepository) {
        this.subjectRepository = subjectRepository;
        this.contentRepository = contentRepository;
        this.programmeRepository = programmeRepository;
        this.announcementRepository = announcementRepository;
        this.quizRepository = quizRepository;
    }

    /**
     * Retrieves subjects (courses) for sync, either all of them or only those
     * updated since the given timestamp.
     *
     * @param since epoch-millisecond timestamp to sync from, or {@code null} for a full sync
     * @return a list of {@link SubjectDTO}, each including its parent programme id if available
     */
    public List<SubjectDTO> getSyncedSubjects(Long since) {
        List<Course> courses;

        if (since == null) {
            courses = subjectRepository.findAllWithProgramme(); // ← use new query
        } else {
            LocalDateTime sinceDate = Instant.ofEpochMilli(since)
                    .atZone(ZoneId.systemDefault())
                    .toLocalDateTime();
            courses = subjectRepository.findByUpdatedAtAfterWithProgramme(sinceDate); // ← use new query
        }

        return courses.stream().map(course -> {
            Long programmeId = null;
            if (course.getProgrammeCourses() != null && !course.getProgrammeCourses().isEmpty()) {
                programmeId = course.getProgrammeCourses().get(0).getProgramme().getId();
            }
            return new SubjectDTO(
                    course.getId(),
                    course.getCourseCode(),
                    course.getName(),
                    course.getDescription(),
                    programmeId
            );
        }).collect(Collectors.toList());
    }

    /**
     * Retrieves content for sync, either all of it or only records updated
     * since the given timestamp.
     *
     * @param since epoch-millisecond timestamp to sync from, or {@code null} for a full sync
     * @return a list of {@link ContentDTO} matching the requested scope
     */
    // Returns all content or only changed ones since last sync
    public List<ContentDTO> getSyncedContent(Long since) {
        if (since == null) {
            return contentRepository.findAll()
                    .stream()
                    .map(c -> ContentDTO.builder()
                            .id(c.getId())
                            .title(c.getTitle())
                            .type(c.getType())
                            .fileUrl(c.getFileUrl())
                            .courseId(c.getCourse() != null ? c.getCourse().getId() : null)
                            .build())
                    .collect(Collectors.toList());
        }
        LocalDateTime sinceDate = Instant.ofEpochMilli(since)
                .atZone(ZoneId.systemDefault())
                .toLocalDateTime();

        return contentRepository.findByUpdatedAtAfter(sinceDate)
                .stream()
                .map(c -> ContentDTO.builder()
                        .id(c.getId())
                        .title(c.getTitle())
                        .type(c.getType())
                        .fileUrl(c.getFileUrl())
                        .courseId(c.getCourse() != null ? c.getCourse().getId() : null)
                        .build())
                .collect(Collectors.toList());
    }

    /**
     * Retrieves programmes for sync, either all of them or only those updated
     * since the given timestamp.
     * <p>
     * Returned as loosely-typed maps rather than a DTO class, keyed by
     * {@code id}, {@code name}, {@code code}, and {@code description}.
     *
     * @param since epoch-millisecond timestamp to sync from, or {@code null} for a full sync
     * @return a list of programme field maps matching the requested scope
     */
    public List<Map<String, Object>> getSyncedProgrammes(Long since) {
        List<Programme> programmes;

        if (since == null) {
            programmes = programmeRepository.findAll();
        } else {
            LocalDateTime sinceDate = Instant.ofEpochMilli(since)
                    .atZone(ZoneId.systemDefault())
                    .toLocalDateTime();
            programmes = programmeRepository.findByUpdatedAtAfter(sinceDate);
        }

        return programmes.stream().map(p -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", p.getId());
            map.put("name", p.getName());
            map.put("code", p.getCode());
            map.put("description", p.getDescription());
            return map;
        }).collect(Collectors.toList());
    }

    /**
     * Retrieves announcements for sync.
     * <p>
     * {@code Announcement} doesn't have an {@code updatedAt} column yet, so
     * this always returns the full set regardless of {@code since} — add
     * that column plus a {@code findByUpdatedAtAfter} query if you want
     * this to become incremental like subjects/content.
     *
     * @param since accepted for API symmetry with the other sync endpoints, currently unused
     * @return every announcement
     */
    public List<Announcement> getSyncedAnnouncements(Long since) {
        return announcementRepository.findAll();
    }

    /**
     * Retrieves quizzes (with their questions) for sync.
     * <p>
     * Same story as announcements: {@code Quiz} has no {@code updatedAt}
     * column, so this is always a full sync for now.
     *
     * @param since accepted for API symmetry with the other sync endpoints, currently unused
     * @return every quiz, including its questions
     */
    public List<QuizDto> getSyncedQuizzes(Long since) {
        // Same DTO that /api/quizzes returns, so no entity serialization.
        return quizRepository.findAll().stream()
                .map(QuizMapper::toDto)
                .collect(Collectors.toList());
    }
}