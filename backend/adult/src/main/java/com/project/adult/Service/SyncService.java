package com.project.adult.Service;

import com.project.adult.DTO.ContentDTO;
import com.project.adult.DTO.SubjectDTO;
import com.project.adult.Repository.ContentRepository;
import com.project.adult.Repository.subjectRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class SyncService {
    private final subjectRepository subjectRepository;
    private final ContentRepository contentRepository;

    public SyncService(subjectRepository subjectRepository, ContentRepository contentRepository) {
        this.subjectRepository = subjectRepository;
        this.contentRepository = contentRepository;
    }

    // Returns all subjects or only changed ones since last sync
    public List<SubjectDTO> getSyncedSubjects(Long since) {
        if (since == null) {
            return subjectRepository.findAll()
                    .stream()
                    .map(p -> new SubjectDTO(p.getId(), p.getCourseCode(), p.getDescription(), p.getName()))
                    .collect(Collectors.toList());
        }
        LocalDateTime sinceDate = Instant.ofEpochMilli(since)
                .atZone(ZoneId.systemDefault())
                .toLocalDateTime();
        return subjectRepository.findByUpdatedAtAfter(sinceDate)
                .stream()
                .map(p -> new SubjectDTO(p.getId(), p.getCourseCode(), p.getDescription(), p.getName()))
                .collect(Collectors.toList());
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
}