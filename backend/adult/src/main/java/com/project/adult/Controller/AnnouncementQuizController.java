package com.project.adult.Controller;

import com.project.adult.Model.Announcement;
import com.project.adult.Model.Quiz;
import com.project.adult.Model.QuizSubmission;
import com.project.adult.Repository.QuizSubmissionRepository;
import com.project.adult.Service.SyncService;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Endpoints for announcements/quizzes on top of the existing /api/sync/*
 * routes (subjects, content, programmes). If you already have a
 * SyncController for those, merge these methods into it instead of running
 * two controllers side by side.
 */
@RestController
@RequestMapping("/api")
public class AnnouncementQuizController {

    private final SyncService syncService;
    private final QuizSubmissionRepository quizSubmissionRepository;

    public AnnouncementQuizController(SyncService syncService, QuizSubmissionRepository quizSubmissionRepository) {
        this.syncService = syncService;
        this.quizSubmissionRepository = quizSubmissionRepository;
    }

    @GetMapping("/sync/announcements")
    public List<Announcement> getAnnouncements(@RequestParam(required = false) Long since) {
        return syncService.getSyncedAnnouncements(since);
    }

    @GetMapping("/sync/quizzes")
    public List<Quiz> getQuizzes(@RequestParam(required = false) Long since) {
        return syncService.getSyncedQuizzes(since);
    }

    /** Called once the device is back online to push a locally-answered quiz. */
    @PostMapping("/quiz/submissions")
    public QuizSubmission submitQuiz(@RequestBody QuizSubmission submission) {
        submission.setSubmittedAt(LocalDateTime.now());
        return quizSubmissionRepository.save(submission);
    }

    @GetMapping("/quiz/submissions")
    public List<QuizSubmission> getSubmissions(@RequestParam String email) {
        return quizSubmissionRepository.findByStudentEmail(email);
    }
}