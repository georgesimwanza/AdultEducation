package com.project.adult.Service;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Model.*;
import com.project.adult.Repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Progress reports for learners, and performance / completion / participation
 * reports and dashboards for administrators and instructors.
 */
@Service
public class ReportService {

    private final UserRepository userRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final EnrollmentService enrollmentService;
    private final UserContentProgressRepository progressRepository;
    private final QuizRepository quizRepository;
    private final QuizSubmissionRepository quizSubmissionRepository;
    private final AssignmentRepository assignmentRepository;
    private final AssignmentSubmissionRepository submissionRepository;
    private final AssignmentService assignmentService;
    private final AttendanceRepository attendanceRepository;
    private final AttendanceService attendanceService;
    private final ActivityEventRepository activityRepository;
    private final NotificationService notificationService;
    private final MessageService messageService;

    public ReportService(UserRepository userRepository,
                         EnrollmentRepository enrollmentRepository,
                         EnrollmentService enrollmentService,
                         UserContentProgressRepository progressRepository,
                         QuizRepository quizRepository,
                         QuizSubmissionRepository quizSubmissionRepository,
                         AssignmentRepository assignmentRepository,
                         AssignmentSubmissionRepository submissionRepository,
                         AssignmentService assignmentService,
                         AttendanceRepository attendanceRepository,
                         AttendanceService attendanceService,
                         ActivityEventRepository activityRepository,
                         NotificationService notificationService,
                         MessageService messageService) {
        this.userRepository = userRepository;
        this.enrollmentRepository = enrollmentRepository;
        this.enrollmentService = enrollmentService;
        this.progressRepository = progressRepository;
        this.quizRepository = quizRepository;
        this.quizSubmissionRepository = quizSubmissionRepository;
        this.assignmentRepository = assignmentRepository;
        this.submissionRepository = submissionRepository;
        this.assignmentService = assignmentService;
        this.attendanceRepository = attendanceRepository;
        this.attendanceService = attendanceService;
        this.activityRepository = activityRepository;
        this.notificationService = notificationService;
        this.messageService = messageService;
    }

    // ── Learner progress report ──────────────────────────────────────

    public LearnerReport learnerReport(User viewer, Long learnerId) {
        User learner = userRepository.findById(learnerId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Learner not found"));
        boolean self = viewer.getId().equals(learnerId);
        if (!self) {
            if (!CurrentUserService.isStaff(viewer)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You can only view your own report");
            }
            CurrentUserService.requireSameInstitution(viewer, CurrentUserService.institutionId(learner));
        }

        List<CourseProgressLine> courses = enrollmentRepository.findByUserWithCourse(learnerId).stream()
                .filter(e -> e.getStatus() != Enrollment.Status.DROPPED)
                .map(e -> new CourseProgressLine(e.getCourse().getId(), e.getCourse().getName(),
                        e.getStatus().name(), enrollmentService.progressFor(learnerId, e.getCourse().getId()),
                        e.getCompletedAt()))
                .toList();
        int avgProgress = (int) Math.round(courses.stream().mapToInt(CourseProgressLine::progressPercentage).average().orElse(0));
        int completed = (int) courses.stream().filter(c -> "COMPLETED".equals(c.status())).count();

        List<GradeLine> grades = new ArrayList<>(quizGrades(learner));
        List<GradeLine> assignmentGrades = submissionRepository.findByLearnerWithAssignment(learnerId).stream()
                .map(s -> new GradeLine(s.getAssignment().getTitle(), s.getAssignment().getCourse().getName(),
                        s.getAssignment().getKind(), s.getScore(), s.getAssignment().getMaxScore(),
                        s.getScore() != null ? percent(s.getScore(), s.getAssignment().getMaxScore()) : null,
                        s.getFeedback(), s.getGradedAt() != null ? s.getGradedAt() : s.getSubmittedAt()))
                .toList();
        grades.addAll(assignmentGrades);
        grades.sort(Comparator.comparing(GradeLine::date, Comparator.nullsLast(Comparator.reverseOrder())));

        Integer avgQuiz = average(grades.stream().filter(g -> "QUIZ".equals(g.kind())).map(GradeLine::percent).toList());
        Integer avgAssignment = average(assignmentGrades.stream().map(GradeLine::percent).toList());

        List<AttendanceRecordDto> attendance = attendanceService.forLearner(learnerId);
        LocalDateTime since = LocalDateTime.now().minusDays(30);

        return new LearnerReport(learner.getId(), ProfileService.fullName(learner), learner.getEmail(),
                learner.getEducationLevel(),
                learner.getSelectedProgramme() != null ? learner.getSelectedProgramme().getName() : null,
                LocalDateTime.now(), courses, avgProgress, completed, avgQuiz, avgAssignment,
                AttendanceService.rateFromDtos(attendance),
                activityRepository.countByUserIdAndCreatedAtAfter(learnerId, since),
                lastActive(learner), grades, attendance);
    }

    private List<GradeLine> quizGrades(User learner) {
        List<QuizSubmission> subs = quizSubmissionRepository.findByStudentEmail(learner.getEmail());
        Map<Long, Quiz> quizzes = quizRepository.findAllById(subs.stream().map(QuizSubmission::getQuizId).toList())
                .stream().collect(Collectors.toMap(Quiz::getId, Function.identity()));
        return subs.stream().map(s -> {
            Quiz q = quizzes.get(s.getQuizId());
            return new GradeLine(q != null ? q.getTitle() : "Quiz", q != null && q.getCourse() != null ? q.getCourse().getName() : null,
                    "QUIZ", s.getScore(), 100, s.getScore(), s.getFeedback(), s.getSubmittedAt());
        }).toList();
    }

    // ── Course performance & completion ──────────────────────────────

    public List<CourseStats> courseStats(User staff) {
        Long institutionId = CurrentUserService.institutionId(staff);
        List<Enrollment> enrollments = institutionId != null
                ? enrollmentRepository.findActiveByInstitution(institutionId)
                : enrollmentRepository.findAll().stream().filter(e -> e.getStatus() != Enrollment.Status.DROPPED).toList();

        // Grouped by id: Lombok's hashCode on Course walks its lazy collections
        Map<Long, List<Enrollment>> byCourse = enrollments.stream()
                .collect(Collectors.groupingBy(e -> e.getCourse().getId(), LinkedHashMap::new, Collectors.toList()));

        List<CourseStats> stats = new ArrayList<>();
        for (List<Enrollment> list : byCourse.values()) {
            Course c = list.get(0).getCourse();
            Set<Long> learnerIds = list.stream().map(e -> e.getUser().getId()).collect(Collectors.toSet());
            Set<String> learnerEmails = list.stream().map(e -> e.getUser().getEmail().toLowerCase()).collect(Collectors.toSet());

            long completed = list.stream().filter(e -> e.getStatus() == Enrollment.Status.COMPLETED).count();
            Map<Long, Short> progress = progressRepository.findByCourse_Id(c.getId()).stream()
                    .collect(Collectors.toMap(p -> p.getUser().getId(), UserContentProgress::getProgressPercentage, (a, b) -> a));
            int avgProgress = (int) Math.round(learnerIds.stream()
                    .mapToInt(id -> progress.getOrDefault(id, (short) 0)).average().orElse(0));

            List<Long> quizIds = quizRepository.findByCourse_Id(c.getId()).stream().map(Quiz::getId).toList();
            Integer avgQuiz = quizIds.isEmpty() ? null : average(quizSubmissionRepository.findByQuizIdIn(quizIds).stream()
                    .filter(s -> learnerEmails.contains(s.getStudentEmail().toLowerCase()))
                    .map(QuizSubmission::getScore).toList());

            Integer avgAssignment = average(submissionRepository.findByCourse(c.getId()).stream()
                    .filter(s -> s.getScore() != null && learnerIds.contains(s.getLearner().getId()))
                    .map(s -> percent(s.getScore(), s.getAssignment().getMaxScore())).toList());

            Integer attendance = AttendanceService.rate(attendanceRepository.findByCourse_Id(c.getId()).stream()
                    .filter(a -> learnerIds.contains(a.getLearner().getId())).toList());

            stats.add(new CourseStats(c.getId(), c.getCourseCode(), c.getName(), list.size(), completed,
                    percent(completed, list.size()), avgProgress, avgQuiz, avgAssignment, attendance));
        }
        stats.sort(Comparator.comparing(CourseStats::enrolled).reversed());
        return stats;
    }

    // ── Participation monitoring ─────────────────────────────────────

    public List<ParticipationLine> participation(User staff) {
        List<User> learners = learnersOf(staff);
        if (learners.isEmpty()) return List.of();
        LocalDateTime since = LocalDateTime.now().minusDays(30);
        Map<Long, Object[]> summary = activityRepository
                .summariseByUser(learners.stream().map(User::getId).toList(), since).stream()
                .collect(Collectors.toMap(r -> (Long) r[0], r -> r));

        List<ParticipationLine> lines = new ArrayList<>();
        for (User u : learners) {
            Object[] row = summary.get(u.getId());
            long events = row != null ? (Long) row[1] : 0;
            LocalDateTime lastEvent = row != null ? (LocalDateTime) row[2] : null;
            LocalDateTime last = latest(lastEvent, u.getLastLoginAt());
            Integer attendance = AttendanceService.rateFromDtos(attendanceService.forLearner(u.getId()));
            int avgProgress = (int) Math.round(progressRepository.findByUserWithCourse(u.getId()).stream()
                    .mapToInt(UserContentProgress::getProgressPercentage).average().orElse(0));

            String status;
            if (events == 0) status = "Inactive";
            else if ((attendance != null && attendance < 60) || (avgProgress < 25 && events < 5)) status = "At risk";
            else status = "Active";

            lines.add(new ParticipationLine(u.getId(), ProfileService.fullName(u), u.getEmail(), events, last,
                    attendance, avgProgress, status));
        }
        // Learners who need attention first
        lines.sort(Comparator.comparing((ParticipationLine p) -> switch (p.status()) {
            case "Inactive" -> 0;
            case "At risk" -> 1;
            default -> 2;
        }).thenComparing(ParticipationLine::name));
        return lines;
    }

    // ── Dashboards ───────────────────────────────────────────────────

    public AdminDashboard adminDashboard(User staff) {
        Long institutionId = CurrentUserService.institutionId(staff);
        List<User> people = institutionId != null ? userRepository.findByInstitutionId(institutionId) : userRepository.findAll();
        long learners = people.stream().filter(u -> u.getRole() == User.Role.USER).count();
        long instructors = people.stream().filter(u -> u.getRole() == User.Role.INSTRUCTOR).count();
        LocalDateTime weekAgo = LocalDateTime.now().minusDays(7);
        List<Long> learnerIds = people.stream().filter(u -> u.getRole() == User.Role.USER).map(User::getId).toList();
        long active7d = learnerIds.isEmpty() ? 0 : activityRepository.summariseByUser(learnerIds, weekAgo).size();

        List<CourseStats> courses = courseStats(staff);
        long enrollments = courses.stream().mapToLong(CourseStats::enrolled).sum();
        long completed = courses.stream().mapToLong(CourseStats::completed).sum();
        int avgProgress = (int) Math.round(courses.stream()
                .mapToDouble(c -> c.averageProgress() * (double) c.enrolled()).sum() / Math.max(1, enrollments));

        List<Assignment> assignments = institutionId != null
                ? assignmentRepository.findByInstitution(institutionId) : assignmentRepository.findAll();
        long pending = assignments.stream()
                .mapToLong(a -> submissionRepository.findByAssignmentWithLearner(a.getId()).stream()
                        .filter(s -> s.getGradedAt() == null).count())
                .sum();
        LocalDateTime now = LocalDateTime.now();
        long upcoming = assignments.stream()
                .filter(a -> a.getDueDate().isAfter(now) && a.getDueDate().isBefore(now.plusDays(7))).count();

        List<ParticipationLine> attention = participation(staff).stream()
                .filter(p -> !"Active".equals(p.status())).limit(10).toList();

        return new AdminDashboard(learners, active7d, instructors, courses.size(), enrollments,
                percent(completed, enrollments), avgProgress, pending, upcoming, courses, attention);
    }

    public LearnerDashboard learnerDashboard(User learner) {
        List<EnrollmentDto> mine = enrollmentService.myCourses(learner).stream()
                .filter(e -> !"DROPPED".equals(e.status())).toList();
        long completed = mine.stream().filter(e -> "COMPLETED".equals(e.status())).count();
        int avgProgress = (int) Math.round(mine.stream().mapToInt(EnrollmentDto::progressPercentage).average().orElse(0));

        LocalDateTime now = LocalDateTime.now();
        List<AssignmentDto> upcoming = assignmentService.listForLearner(learner).stream()
                .filter(a -> a.mySubmission() == null && a.dueDate().isAfter(now))
                .sorted(Comparator.comparing(AssignmentDto::dueDate))
                .limit(5).toList();

        LearnerReport report = learnerReport(learner, learner.getId());
        List<EnrollmentDto> continueLearning = mine.stream()
                .filter(e -> "ACTIVE".equals(e.status()))
                .sorted(Comparator.comparing(EnrollmentDto::lastAccessed, Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(3).toList();

        return new LearnerDashboard(mine.size(), completed, avgProgress, report.averageQuizScore(),
                report.attendanceRate(), notificationService.unreadCount(learner.getId()),
                messageService.unreadCount(learner), upcoming,
                report.grades().stream().filter(g -> g.score() != null).limit(5).toList(),
                continueLearning);
    }

    // ── CSV export ───────────────────────────────────────────────────

    public String courseStatsCsv(User staff) {
        StringBuilder sb = new StringBuilder(
                "Course code,Course,Enrolled,Completed,Completion rate %,Average progress %,Average quiz %,Average assignment %,Attendance %\n");
        for (CourseStats c : courseStats(staff)) {
            sb.append(csv(c.courseCode())).append(',').append(csv(c.courseName())).append(',')
                    .append(c.enrolled()).append(',').append(c.completed()).append(',')
                    .append(c.completionRate()).append(',').append(c.averageProgress()).append(',')
                    .append(blank(c.averageQuizScore())).append(',').append(blank(c.averageAssignmentPercent())).append(',')
                    .append(blank(c.attendanceRate())).append('\n');
        }
        return sb.toString();
    }

    public String participationCsv(User staff) {
        StringBuilder sb = new StringBuilder("Learner,Email,Status,Activity (30 days),Last active,Attendance %,Average progress %\n");
        for (ParticipationLine p : participation(staff)) {
            sb.append(csv(p.name())).append(',').append(csv(p.email())).append(',').append(p.status()).append(',')
                    .append(p.eventsLast30Days()).append(',').append(p.lastActive() != null ? p.lastActive() : "").append(',')
                    .append(blank(p.attendanceRate())).append(',').append(p.averageProgress()).append('\n');
        }
        return sb.toString();
    }

    // ── Helpers ──────────────────────────────────────────────────────

    private List<User> learnersOf(User staff) {
        Long institutionId = CurrentUserService.institutionId(staff);
        List<User> people = institutionId != null ? userRepository.findByInstitutionId(institutionId) : userRepository.findAll();
        return people.stream().filter(u -> u.getRole() == User.Role.USER).toList();
    }

    private LocalDateTime lastActive(User u) {
        LocalDateTime lastEvent = activityRepository
                .findByUserIdOrderByCreatedAtDesc(u.getId(), org.springframework.data.domain.PageRequest.of(0, 1))
                .stream().findFirst().map(ActivityEvent::getCreatedAt).orElse(null);
        return latest(lastEvent, u.getLastLoginAt());
    }

    private static LocalDateTime latest(LocalDateTime a, LocalDateTime b) {
        if (a == null) return b;
        if (b == null) return a;
        return a.isAfter(b) ? a : b;
    }

    private static int percent(long part, long whole) {
        return whole == 0 ? 0 : (int) Math.round(part * 100.0 / whole);
    }

    private static Integer average(List<Integer> values) {
        List<Integer> present = values.stream().filter(Objects::nonNull).toList();
        if (present.isEmpty()) return null;
        return (int) Math.round(present.stream().mapToInt(Integer::intValue).average().orElse(0));
    }

    private static String blank(Integer v) {
        return v == null ? "" : v.toString();
    }

    private static String csv(String v) {
        if (v == null) return "";
        // Neutralise spreadsheet formulas and quote fields containing separators
        String safe = v.matches("^[=+\\-@].*") ? "'" + v : v;
        return "\"" + safe.replace("\"", "\"\"") + "\"";
    }
}
