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

/**
 * Service layer for managing {@link Content} entities (course materials).
 * <p>
 * Handles creation and retrieval of content, converting between the
 * {@link Content} entity and {@link ContentDTO} to avoid exposing raw
 * JPA entities (and their nested-object/infinite-loop risk) to callers.
 */
@Service
public class ContentService {
    private final ContentRepository contentRepository;
    private final CourseRepository courseRepository;
    private final InstitutionRepository institutionRepository; // ← added

    /**
     * Constructs the service with its required repositories.
     *
     * @param contentRepository     repository for persisting and querying content
     * @param courseRepository      repository for looking up the parent course
     * @param institutionRepository repository for looking up the associated institution
     */
    public ContentService(ContentRepository contentRepository,
                          CourseRepository courseRepository,
                          InstitutionRepository institutionRepository) {
        this.contentRepository = contentRepository;
        this.courseRepository = courseRepository;
        this.institutionRepository = institutionRepository;
    }

    /**
     * Creates a new piece of content and attaches it to its course, and
     * optionally its institution, before saving.
     *
     * @param contentDTO the incoming content data, including the target course id
     *                   and, optionally, an institution id
     * @return a {@link ContentDTO} representing the newly saved content
     * @throws RuntimeException if the referenced course does not exist, or if
     *                          an institution id is provided but does not exist
     */
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

    /**
     * Retrieves all content belonging to a given subject.
     *
     * @param id the subject id to look up content for
     * @return a list of {@link ContentDTO} for the given subject
     */
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
    /**
     * Retrieves all content in the system.
     *
     * @return a list of {@link ContentDTO} for every content record
     */
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