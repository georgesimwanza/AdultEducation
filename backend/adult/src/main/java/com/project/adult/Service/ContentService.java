package com.project.adult.Service;

import com.project.adult.DTO.ContentDTO;
import com.project.adult.Model.Content;
import com.project.adult.Model.Course;
import com.project.adult.Model.Institution;
import com.project.adult.Repository.ContentRepository;
import com.project.adult.Repository.CourseRepository;
import com.project.adult.Repository.InstitutionRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ContentService {
    private final ContentRepository contentRepository;
    private final CourseRepository courseRepository;
    private final InstitutionRepository institutionRepository; // ← added

    public ContentService(ContentRepository contentRepository,
                          CourseRepository courseRepository,
                          InstitutionRepository institutionRepository) {
        this.contentRepository = contentRepository;
        this.courseRepository = courseRepository;
        this.institutionRepository = institutionRepository;
    }

    public ContentDTO addContent(ContentDTO contentDTO) {
        Course course = courseRepository.findById(contentDTO.getCourseId())
                .orElseThrow(() -> new RuntimeException("Course not found"));

        Content content = new Content();
        content.setTitle(contentDTO.getTitle());
        content.setType(contentDTO.getType());
        content.setFileUrl(contentDTO.getFileUrl());
        content.setCourse(course);

        // ← now actually looks up and attaches institution
        if (contentDTO.getInstitutionId() != null) {
            Institution institution = institutionRepository.findById(contentDTO.getInstitutionId())
                    .orElseThrow(() -> new RuntimeException("Institution not found"));
            content.setInstitution(institution);
        }

        Content saved = contentRepository.save(content);

        return ContentDTO.builder()
                .id(saved.getId())
                .title(saved.getTitle())
                .type(saved.getType())
                .fileUrl(saved.getFileUrl())
                .courseId(contentDTO.getCourseId())
                .institutionId(saved.getInstitution() != null ? saved.getInstitution().getId() : null) // ← added
                .build();
    }

    public List<ContentDTO> getContentById(Long id) {
        return contentRepository.findContentbySubjectId(id)
                .stream()
                .map(c -> ContentDTO.builder()
                        .id(c.getId())
                        .type(c.getType())
                        .title(c.getTitle())
                        .fileUrl(c.getFileUrl())
                        .courseId(c.getCourse() != null ? c.getCourse().getId() : null)
                        .institutionId(c.getInstitution() != null ? c.getInstitution().getId() : null) // ← added
                        .build())
                .collect(Collectors.toList());
    }

    // ← now returns DTOs instead of raw entities, fixes nested-object/infinite-loop risk
    public List<ContentDTO> getAllContent() {
        return contentRepository.findAll()
                .stream()
                .map(c -> ContentDTO.builder()
                        .id(c.getId())
                        .type(c.getType())
                        .title(c.getTitle())
                        .fileUrl(c.getFileUrl())
                        .courseId(c.getCourse() != null ? c.getCourse().getId() : null)
                        .institutionId(c.getInstitution() != null ? c.getInstitution().getId() : null)
                        .build())
                .collect(Collectors.toList());
    }
}