package com.project.adult.Model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "programmes")
public class Programme {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(columnDefinition = "uuid DEFAULT uuid_generate_v4()", unique = true, nullable = false,
            updatable = false)
    private java.util.UUID uuid;

    @Column(name = "name", nullable = false, length = 255)
    private String name;

    @Column(name = "code", unique = true, nullable = false, length = 50)
    private String code;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "icon_name", length = 100)
    private String iconName;

    @Column(name = "icon_bg", length = 7)
    private String iconBg;               // hex colour e.g. "#F7DF1E"

    @Column(name = "icon_color", length = 7)
    private String iconColor;

    @Column(name = "duration_years", precision = 3, scale = 1)
    private BigDecimal durationYears;

    @Column(name = "total_credits")
    private Integer totalCredits;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    // Users enrolled in this programme
    @OneToMany(mappedBy = "selectedProgramme")
    private List<User> users;

    // Courses in this programme (via junction table)
    @OneToMany(mappedBy = "programme", cascade = CascadeType.ALL)
    private List<ProgrammeCourse> programmeCourses;

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}