package com.project.adult.Controller;

import com.project.adult.DTO.QuizDto;
import com.project.adult.Model.Announcement;
import com.project.adult.Model.Quiz;
import com.project.adult.Model.QuizSubmission;
import com.project.adult.Model.ActivityEvent;
import com.project.adult.Model.User;
import com.project.adult.Repository.QuizRepository;
import com.project.adult.Repository.QuizSubmissionRepository;
import com.project.adult.Service.ActivityService;
import com.project.adult.Service.CurrentUserService;
import com.project.adult.Service.SyncService;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
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
    private final QuizRepository quizRepository;
    private final CurrentUserService currentUser;
    private final ActivityService activityService;

    public AnnouncementQuizController(SyncService syncService,
                                      QuizSubmissionRepository quizSubmissionRepository,
                                      QuizRepository quizRepository,
                                      CurrentUserService currentUser,
                                      ActivityService activityService) {
        this.syncService = syncService;
        this.quizSubmissionRepository = quizSubmissionRepository;
        this.quizRepository = quizRepository;
        this.currentUser = currentUser;
        this.activityService = activityService;
    }

    @GetMapping("/sync/announcements")
    public List<Announcement> getAnnouncements(@RequestParam(required = false) Long since) {
        return syncService.getSyncedAnnouncements(since);
    }

    @GetMapping("/sync/quizzes")
    public List<QuizDto> getQuizzes(@RequestParam(required = false) Long since) {
        return syncService.getSyncedQuizzes(since);
    }

    /** Called once the device is back online to push a locally-answered quiz. */
    @PostMapping("/quiz/submissions")
    public QuizSubmission submitQuiz(@RequestBody QuizSubmission submission) {
        // The attempt always belongs to the signed-in learner, whatever the body says
        User me = currentUser.require();
        submission.setId(null);
        submission.setStudentEmail(me.getEmail());
        submission.setFeedback(null);
        submission.setGradedAt(null);
        submission.setSubmittedAt(LocalDateTime.now());
        QuizSubmission saved = quizSubmissionRepository.save(submission);
        Long courseId = quizRepository.findById(submission.getQuizId())
                .map(q -> q.getCourse() != null ? q.getCourse().getId() : null).orElse(null);
        activityService.record(me.getId(), ActivityEvent.Type.SUBMIT_QUIZ, courseId, "Submitted quiz " + submission.getQuizId());
        return saved;
    }

    @GetMapping("/quiz/submissions")
    public List<QuizSubmission> getSubmissions(@RequestParam String email) {
        User me = currentUser.require();
        if (!CurrentUserService.isStaff(me) && !me.getEmail().equalsIgnoreCase(email)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You can only view your own submissions");
        }
        return quizSubmissionRepository.findByStudentEmail(email);
    }
}