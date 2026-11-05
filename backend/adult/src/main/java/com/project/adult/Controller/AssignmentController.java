package com.project.adult.Controller;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Service.AssignmentService;
import com.project.adult.Service.CurrentUserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Assignments and tests, submissions, and grading with feedback (including quiz attempts). */
@RestController
public class AssignmentController {

    private static final String STAFF = "hasAnyRole('ADMIN','INSTRUCTOR','INSTITUTION')";

    private final AssignmentService assignmentService;
    private final CurrentUserService currentUser;

    public AssignmentController(AssignmentService assignmentService, CurrentUserService currentUser) {
        this.assignmentService = assignmentService;
        this.currentUser = currentUser;
    }

    // ── Learner ──────────────────────────────────────────────────────

    @GetMapping("/api/assignments/mine")
    public List<AssignmentDto> mine() {
        return assignmentService.listForLearner(currentUser.require());
    }

    @PostMapping("/api/assignments/{id}/submit")
    public SubmissionDto submit(@PathVariable Long id, @RequestBody SubmitRequest request) {
        return assignmentService.submit(currentUser.require(), id, request);
    }

    // ── Staff ────────────────────────────────────────────────────────

    @PreAuthorize(STAFF)
    @GetMapping("/api/assignments/manage")
    public List<AssignmentDto> manage() {
        return assignmentService.listForStaff(currentUser.require());
    }

    @PreAuthorize(STAFF)
    @PostMapping("/api/assignments")
    public AssignmentDto create(@RequestBody AssignmentRequest request) {
        return assignmentService.create(currentUser.require(), request);
    }

    @PreAuthorize(STAFF)
    @PutMapping("/api/assignments/{id}")
    public AssignmentDto update(@PathVariable Long id, @RequestBody AssignmentRequest request) {
        return assignmentService.update(currentUser.require(), id, request);
    }

    @PreAuthorize(STAFF)
    @DeleteMapping("/api/assignments/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        assignmentService.delete(currentUser.require(), id);
        return ResponseEntity.noContent().build();
    }

    @PreAuthorize(STAFF)
    @GetMapping("/api/assignments/{id}/submissions")
    public List<SubmissionDto> submissions(@PathVariable Long id) {
        return assignmentService.submissions(currentUser.require(), id);
    }

    @PreAuthorize(STAFF)
    @PutMapping("/api/assignments/submissions/{submissionId}/grade")
    public SubmissionDto grade(@PathVariable Long submissionId, @RequestBody GradeRequest request) {
        return assignmentService.grade(currentUser.require(), submissionId, request);
    }

    // ── Quiz grading ─────────────────────────────────────────────────

    @PreAuthorize(STAFF)
    @GetMapping("/api/quiz-grading/{quizId}/submissions")
    public List<QuizSubmissionDto> quizSubmissions(@PathVariable Long quizId) {
        return assignmentService.quizSubmissions(currentUser.require(), quizId);
    }

    @PreAuthorize(STAFF)
    @PutMapping("/api/quiz-grading/submissions/{submissionId}")
    public QuizSubmissionDto gradeQuiz(@PathVariable Long submissionId, @RequestBody GradeRequest request) {
        return assignmentService.gradeQuiz(currentUser.require(), submissionId, request);
    }
}
