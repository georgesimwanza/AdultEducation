package com.project.adult.Model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;


@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "programme_courses")
public class ProgrammeCourse {

    @EmbeddedId
    private ProgrammeCourseId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("programmeId")
    @JoinColumn(name = "programme_id", nullable = false)
    @JsonIgnoreProperties({"programmeCourses", "users"})
    private Programme programme;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("courseId")
    @JoinColumn(name = "course_id", nullable = false)

    @JsonIgnoreProperties({"programmeCourses", "userContentProgresses", "contents"})
    private Course course;

    @Column(name = "is_required", nullable = false)
    private Boolean isRequired = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
}