package com.project.adult.Controller;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Service.CurrentUserService;
import com.project.adult.Service.EnrollmentService;
import com.project.adult.Service.ProgressService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Course catalogue, enrollment, course history and lesson progress. */
@RestController
public class EnrollmentController {

    private final EnrollmentService enrollmentService;
    private final ProgressService progressService;
    private final CurrentUserService currentUser;

    public EnrollmentController(EnrollmentService enrollmentService,
                                ProgressService progressService,
                                CurrentUserService currentUser) {
        this.enrollmentService = enrollmentService;
        this.progressService = progressService;
        this.currentUser = currentUser;
    }

    @GetMapping("/api/enrollments/catalogue")
    public List<CourseSummary> catalogue() {
        return enrollmentService.catalogue(currentUser.require());
    }

    /** The learner's course history with progress. */
    @GetMapping("/api/enrollments/me")
    public List<EnrollmentDto> myCourses() {
        return enrollmentService.myCourses(currentUser.require());
    }

    @PostMapping("/api/enrollments/{courseId}")
    public EnrollmentDto enroll(@PathVariable Long courseId) {
        return enrollmentService.enroll(currentUser.require(), courseId);
    }

    @DeleteMapping("/api/enrollments/{courseId}")
    public ResponseEntity<Void> drop(@PathVariable Long courseId) {
        enrollmentService.drop(currentUser.require(), courseId);
        return ResponseEntity.noContent().build();
    }

    @PreAuthorize("hasAnyRole('ADMIN','INSTRUCTOR','INSTITUTION')")
    @GetMapping("/api/enrollments/course/{courseId}/roster")
    public List<RosterEntry> roster(@PathVariable Long courseId) {
        return enrollmentService.roster(currentUser.require(), courseId);
    }

    /** Called by the app whenever a learner opens a lesson. */
    @PostMapping("/api/progress/lessons/{contentId}/view")
    public LessonViewResult lessonViewed(@PathVariable Long contentId) {
        return progressService.recordLessonView(currentUser.require(), contentId);
    }
}
