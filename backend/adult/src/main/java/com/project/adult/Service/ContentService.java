package com.project.adult.Service;


import com.project.adult.DTO.ContentDTO;
import com.project.adult.Model.Content;
import com.project.adult.Model.Course;
import com.project.adult.Repository.ContentRepository;
import com.project.adult.Repository.CourseRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.List;
import java.util.stream.Collectors;
@Service
public class ContentService {
    private final ContentRepository contentRepository;
    private final CourseRepository courseRepository; // ← add this

    // ← update constructor to inject both
    public ContentService(ContentRepository contentRepository, CourseRepository courseRepository) {
        this.contentRepository = contentRepository;
        this.courseRepository = courseRepository;
    }

    public ContentDTO addContent(ContentDTO contentDTO) {
        Course course = courseRepository.findById((contentDTO.getCourseId()))
                .orElseThrow(() -> new RuntimeException("Course not found"));

        Content content = new Content();
        content.setTitle(contentDTO.getTitle());
        content.setType(contentDTO.getType());
        content.setFileUrl(contentDTO.getFileUrl());
        content.setCourse(course);

        Content saved = contentRepository.save(content);

        return ContentDTO.builder()
                .id(saved.getId())
                .title(saved.getTitle())
                .type(saved.getType())
                .fileUrl(saved.getFileUrl())
                .courseId(contentDTO.getCourseId())
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
                        .build())
                .collect(Collectors.toList());
    }
}