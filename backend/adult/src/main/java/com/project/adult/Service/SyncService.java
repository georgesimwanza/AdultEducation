package com.project.adult.Service;

import com.project.adult.DTO.ContentDTO;
import com.project.adult.DTO.SubjectDTO;
import com.project.adult.Model.Course;
import com.project.adult.Model.Programme;
import com.project.adult.Repository.ContentRepository;
import com.project.adult.Repository.ProgrammeRepository;
import com.project.adult.Repository.subjectRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@Transactional
public class SyncService {
    private final subjectRepository subjectRepository;
    private final ContentRepository contentRepository;
    private final ProgrammeRepository programmeRepository;
    public SyncService(subjectRepository subjectRepository, ContentRepository contentRepository, ProgrammeRepository programmeRepository) {
        this.subjectRepository = subjectRepository;
        this.contentRepository = contentRepository;
        this.programmeRepository = programmeRepository;
    }

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
}