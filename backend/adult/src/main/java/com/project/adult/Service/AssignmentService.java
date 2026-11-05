package com.project.adult.Service;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Model.*;
import com.project.adult.Repository.*;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Assignments and tests: instructors set them with a deadline, learners
 * submit an answer (text and/or an uploaded file link), and instructors
 * grade them with feedback. Quiz attempts can also be given a grade and
 * feedback here.
 */
@Service
public class AssignmentService {

    private final AssignmentRepository assignmentRepository;
    private final AssignmentSubmissionRepository submissionRepository;
    private final CourseRepository courseRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final QuizRepository quizRepository;
    private final QuizSubmissionRepository quizSubmissionRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final ActivityService activityService;

    public AssignmentService(AssignmentRepository assignmentRepository,
                             AssignmentSubmissionRepository submissionRepository,
                             CourseRepository courseRepository,
                             EnrollmentRepository enrollmentRepository,
                             QuizRepository quizRepository,
                             QuizSubmissionRepository quizSubmissionRepository,
                             UserRepository userRepository,
                             NotificationService notificationService,
                             ActivityService activityService) {
        this.assignmentRepository = assignmentRepository;
        this.submissionRepository = submissionRepository;
        this.courseRepository = courseRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.quizRepository = quizRepository;
        this.quizSubmissionRepository = quizSubmissionRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
        this.activityService = activityService;
    }

    // ── Staff ────────────────────────────────────────────────────────

    @Transactional
    public AssignmentDto create(User staff, AssignmentRequest req) {
        Assignment a = new Assignment();
        apply(a, req);
        a.setInstitution(staff.getInstitution());
        a.setCreatedBy(staff);
        a = assignmentRepository.save(a);
        notificationService.announceNewAssignment(a);
        return toDto(a, null);
    }

    @Transactional
    public AssignmentDto update(User staff, Long id, AssignmentRequest req) {
        Assignment a = staffAssignment(staff, id);
        LocalDateTime oldDue = a.getDueDate();
        apply(a, req);
        if (!a.getDueDate().equals(oldDue)) a.setReminderSent(false);
        return toDto(assignmentRepository.save(a), null);
    }

    @Transactional
    public void delete(User staff, Long id) {
        Assignment a = staffAssignment(staff, id);
        submissionRepository.deleteAll(submissionRepository.findByAssignmentWithLearner(id));
        assignmentRepository.delete(a);
    }

    public List<AssignmentDto> listForStaff(User staff) {
        Long institutionId = CurrentUserService.institutionId(staff);
        List<Assignment> list = institutionId != null
                ? assignmentRepository.findByInstitution(institutionId)
                : assignmentRepository.findAll();
        return list.stream().map(a -> toDto(a, null)).toList();
    }

    public List<SubmissionDto> submissions(User staff, Long assignmentId) {
        Assignment a = staffAssignment(staff, assignmentId);
        return submissionRepository.findByAssignmentWithLearner(a.getId()).stream()
                .map(this::toDto).toList();
    }

    @Transactional
    public SubmissionDto grade(User staff, Long submissionId, GradeRequest req) {
        AssignmentSubmission s = submissionRepository.findById(submissionId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Submission not found"));
        Assignment a = staffAssignment(staff, s.getAssignment().getId());
        if (req.score() == null || req.score() < 0 || req.score() > a.getMaxScore()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Score must be between 0 and " + a.getMaxScore());
        }
        s.setScore(req.score());
        s.setFeedback(req.feedback() != null ? req.feedback().trim() : null);
        s.setGradedAt(LocalDateTime.now());
        s.setGradedBy(staff);
        submissionRepository.save(s);
        notificationService.notify(s.getLearner().getId(), Notification.Type.GRADE,
                "Graded: " + a.getTitle(),
                "You scored " + req.score() + "/" + a.getMaxScore()
                        + (s.getFeedback() != null && !s.getFeedback().isBlank() ? ". Feedback: " + s.getFeedback() : ""));
        return toDto(s);
    }

    // ── Learner ──────────────────────────────────────────────────────

    /** Work set for the courses the learner is enrolled in, with their own submission attached. */
    public List<AssignmentDto> listForLearner(User learner) {
        List<Long> courseIds = enrollmentRepository.findByUserWithCourse(learner.getId()).stream()
                .filter(e -> e.getStatus() != Enrollment.Status.DROPPED)
                .map(e -> e.getCourse().getId())
                .toList();
        if (courseIds.isEmpty()) return List.of();
        Map<Long, AssignmentSubmission> mine = submissionRepository.findByLearnerWithAssignment(learner.getId()).stream()
                .collect(Collectors.toMap(s -> s.getAssignment().getId(), Function.identity(), (x, y) -> x));
        return assignmentRepository.findByCourseIds(courseIds).stream()
                .map(a -> toDto(a, mine.get(a.getId())))
                .toList();
    }

    @Transactional
    public SubmissionDto submit(User learner, Long assignmentId, SubmitRequest req) {
        Assignment a = assignmentRepository.findById(assignmentId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Assignment not found"));
        boolean enrolled = enrollmentRepository.findByUser_IdAndCourse_Id(learner.getId(), a.getCourse().getId())
                .filter(e -> e.getStatus() != Enrollment.Status.DROPPED)
                .isPresent();
        if (!enrolled) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Enroll in the course first");
        }
        boolean hasText = req.answerText() != null && !req.answerText().isBlank();
        boolean hasFile = req.fileUrl() != null && !req.fileUrl().isBlank();
        if (!hasText && !hasFile) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Write an answer or attach a file");
        }
        AssignmentSubmission s = submissionRepository.findByAssignment_IdAndLearner_Id(assignmentId, learner.getId())
                .orElseGet(AssignmentSubmission::new);
        if (s.getGradedAt() != null) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "This work has already been graded");
        }
        s.setAssignment(a);
        s.setLearner(learner);
        s.setAnswerText(hasText ? req.answerText().trim() : null);
        s.setFileUrl(hasFile ? req.fileUrl().trim() : null);
        s.setSubmittedAt(LocalDateTime.now());
        s = submissionRepository.save(s);
        activityService.record(learner.getId(), ActivityEvent.Type.SUBMIT_ASSIGNMENT, a.getCourse().getId(),
                "Submitted " + a.getTitle());
        return toDto(s);
    }

    // ── Quiz grading ─────────────────────────────────────────────────

    public List<QuizSubmissionDto> quizSubmissions(User staff, Long quizId) {
        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Quiz not found"));
        CurrentUserService.requireSameInstitution(staff,
                quiz.getInstitution() != null ? quiz.getInstitution().getId() : null);
        return quizSubmissionRepository.findByQuizId(quizId).stream()
                .map(s -> toQuizDto(s, quiz)).toList();
    }

    @Transactional
    public QuizSubmissionDto gradeQuiz(User staff, Long submissionId, GradeRequest req) {
        QuizSubmission s = quizSubmissionRepository.findById(submissionId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Submission not found"));
        Quiz quiz = quizRepository.findById(s.getQuizId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Quiz not found"));
        CurrentUserService.requireSameInstitution(staff,
                quiz.getInstitution() != null ? quiz.getInstitution().getId() : null);
        if (req.score() != null) {
            if (req.score() < 0 || req.score() > 100) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Quiz score is a percentage from 0 to 100");
            }
            s.setScore(req.score());
        }
        s.setFeedback(req.feedback() != null ? req.feedback().trim() : null);
        s.setGradedAt(LocalDateTime.now());
        quizSubmissionRepository.save(s);
        userRepository.findByEmailIgnoreCase(s.getStudentEmail()).ifPresent(learner ->
                notificationService.notify(learner.getId(), Notification.Type.GRADE,
                        "Quiz graded: " + quiz.getTitle(),
                        "Your score: " + (s.getScore() != null ? s.getScore() + "%" : "—")
                                + (s.getFeedback() != null && !s.getFeedback().isBlank() ? ". Feedback: " + s.getFeedback() : "")));
        return toQuizDto(s, quiz);
    }

    QuizSubmissionDto toQuizDto(QuizSubmission s, Quiz quiz) {
        String name = userRepository.findByEmailIgnoreCase(s.getStudentEmail())
                .map(ProfileService::fullName).orElse(s.getStudentEmail());
        return new QuizSubmissionDto(s.getId(), s.getQuizId(), quiz != null ? quiz.getTitle() : null,
                quiz != null && quiz.getCourse() != null ? quiz.getCourse().getName() : null,
                s.getStudentEmail(), name, s.getScore(), s.getFeedback(), s.getSubmittedAt(),
                s.getGradedAt(), s.getAnswersJson());
    }

    // ── Helpers ──────────────────────────────────────────────────────

    private void apply(Assignment a, AssignmentRequest req) {
        if (req.title() == null || req.title().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Title is required");
        }
        if (req.dueDate() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Due date is required");
        }
        if (req.courseId() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Course is required");
        }
        Course course = courseRepository.findById(req.courseId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.BAD_REQUEST, "Course not found"));
        a.setCourse(course);
        a.setTitle(req.title().trim());
        a.setDescription(req.description());
        a.setKind("TEST".equalsIgnoreCase(req.kind()) ? "TEST" : "ASSIGNMENT");
        a.setDueDate(req.dueDate());
        a.setMaxScore(req.maxScore() != null && req.maxScore() > 0 ? req.maxScore() : 100);
    }

    private Assignment staffAssignment(User staff, Long id) {
        Assignment a = assignmentRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Assignment not found"));
        CurrentUserService.requireSameInstitution(staff,
                a.getInstitution() != null ? a.getInstitution().getId() : null);
        return a;
    }

    AssignmentDto toDto(Assignment a, AssignmentSubmission mine) {
        List<AssignmentSubmission> all = mine == null
                ? submissionRepository.findByAssignmentWithLearner(a.getId())
                : List.of();
        return new AssignmentDto(a.getId(), a.getCourse().getId(), a.getCourse().getName(), a.getTitle(),
                a.getDescription(), a.getKind(), a.getDueDate(), a.getMaxScore(), a.getCreatedAt(),
                all.size(), all.stream().filter(s -> s.getGradedAt() != null).count(),
                mine != null ? toDto(mine) : null);
    }

    SubmissionDto toDto(AssignmentSubmission s) {
        Assignment a = s.getAssignment();
        return new SubmissionDto(s.getId(), a.getId(), a.getTitle(), s.getLearner().getId(),
                ProfileService.fullName(s.getLearner()), s.getAnswerText(), s.getFileUrl(),
                s.getSubmittedAt(), s.getScore(), a.getMaxScore(), s.getFeedback(), s.getGradedAt(),
                s.getSubmittedAt().isAfter(a.getDueDate()));
    }
}
