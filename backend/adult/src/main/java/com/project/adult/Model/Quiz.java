package com.project.adult.Model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "quizzes")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Quiz {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 255)
    private String title;

    @Column(length = 2000)
    private String description;

    /**
     * FK to your Subject entity. Kept as a plain Long rather than a
     * @ManyToOne to avoid guessing at your Subject entity's shape — wire
     * up a real relationship here later if you want cascade/fetch control.
     */
    @JoinColumn(name = "institution_id", nullable = false)
    @ManyToOne
    // Widened to match Announcement.institution's ignore list — ignoring
    // only "quiz" left Jackson free to walk institution.programmes ->
    // programme.institution -> ... in a circle (that's what produced the
    // depth-500 nesting error on the announcements endpoint).
    @JsonIgnoreProperties({"contents", "quiz", "programmes", "students", "announcements", "hibernateLazyInitializer", "handler"})
    private Institution institution;
    @JoinColumn(name = "programme_id", nullable = false)
    @ManyToOne
    @JsonIgnoreProperties({"users", "programmeCourses", "institution", "students", "announcements", "quiz", "hibernateLazyInitializer", "handler"})
    private Programme programme;

    /**
     * FK to your Course entity. The ignored property names here
     * ("content", "programmeCourses", "quiz") are a best guess based on
     * how Course is used elsewhere in SyncService — verify against your
     * actual Course entity's field names, or share Course.java and I'll
     * correct this.
     */
    @JoinColumn(name = "course_id", nullable = false)
    @ManyToOne
    @JsonIgnoreProperties({"content", "programmeCourses", "quiz", "institution", "hibernateLazyInitializer", "handler"})
    private Course course;

    /**
     * cascade=ALL + orphanRemoval=true means: saving a Quiz with a
     * modified question list automatically inserts new questions, updates
     * existing ones, and deletes any that were removed — matching how the
     * Flutter admin screen always sends the full, updated question list.
     * @OrderColumn persists list order so reordering in the app sticks.
     */
    @OneToMany(mappedBy = "quiz", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderColumn(name = "question_order")
    @JsonIgnoreProperties({"quiz", "hibernateLazyInitializer", "handler"})
    private List<Question> questions = new ArrayList<>();

    private Integer timeLimitMinutes;

    @Column(nullable = false)
    private int passingScorePercent = 50;


    public Quiz(String title, String description, Long subjectId, Long institutionId) {
    }
}