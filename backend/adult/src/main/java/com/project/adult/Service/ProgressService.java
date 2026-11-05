package com.project.adult.Service;

import com.project.adult.DTO.LearningDtos.LessonViewResult;
import com.project.adult.Model.*;
import com.project.adult.Repository.*;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Tracks learning progress. Each time a learner opens a lesson the app
 * reports it here; course progress is the share of the course's lessons
 * the learner has opened at least once.
 */
@Service
public class ProgressService {

    private final ContentRepository contentRepository;
    private final ContentViewRepository contentViewRepository;
    private final UserContentProgressRepository progressRepository;
    private final EnrollmentService enrollmentService;
    private final EnrollmentRepository enrollmentRepository;
    private final AttendanceRepository attendanceRepository;
    private final ActivityService activityService;
    private final NotificationService notificationService;

    public ProgressService(ContentRepository contentRepository,
                           ContentViewRepository contentViewRepository,
                           UserContentProgressRepository progressRepository,
                           EnrollmentService enrollmentService,
                           EnrollmentRepository enrollmentRepository,
                           AttendanceRepository attendanceRepository,
                           ActivityService activityService,
                           NotificationService notificationService) {
        this.contentRepository = contentRepository;
        this.contentViewRepository = contentViewRepository;
        this.progressRepository = progressRepository;
        this.enrollmentService = enrollmentService;
        this.enrollmentRepository = enrollmentRepository;
        this.attendanceRepository = attendanceRepository;
        this.activityService = activityService;
        this.notificationService = notificationService;
    }

    @Transactional
    public LessonViewResult recordLessonView(User learner, Long contentId) {
        Content content = contentRepository.findById(contentId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Lesson not found"));
        Course course = content.getCourse();
        LocalDateTime now = LocalDateTime.now();

        // Opening a lesson implies the learner is taking the course
        Enrollment enrollment = enrollmentService.ensureEnrolled(learner, course);

        ContentView view = contentViewRepository.findByUser_IdAndContent_Id(learner.getId(), contentId)
                .orElse(null);
        if (view == null) {
            view = new ContentView();
            view.setUser(learner);
            view.setContent(content);
            view.setCourseId(course.getId());
        } else {
            view.setViewCount(view.getViewCount() + 1);
            view.setLastViewedAt(now);
        }
        contentViewRepository.save(view);

        long total = contentRepository.countByCourse_Id(course.getId());
        long viewed = contentViewRepository.countByUser_IdAndCourseId(learner.getId(), course.getId());
        int percent = total == 0 ? 0 : (int) Math.min(100, Math.round(viewed * 100.0 / total));

        UserContentProgress progress = progressRepository.findByUser_IdAndCourse_Id(learner.getId(), course.getId())
                .orElseGet(() -> {
                    UserContentProgress p = new UserContentProgress();
                    p.setUser(learner);
                    p.setCourse(course);
                    return p;
                });
        boolean newlyCompleted = percent >= 100 && !Boolean.TRUE.equals(progress.getIsCompleted());
        progress.setProgressPercentage((short) percent);
        progress.setLastAccessed(now);
        if (newlyCompleted) {
            progress.setIsCompleted(true);
            progress.setCompletedAt(now);
        }
        progressRepository.save(progress);

        if (newlyCompleted) {
            enrollment.setStatus(Enrollment.Status.COMPLETED);
            enrollment.setCompletedAt(now);
            enrollmentRepository.save(enrollment);
            notificationService.notify(learner.getId(), Notification.Type.COURSE,
                    "Course completed: " + course.getName(),
                    "Well done! You have finished every lesson in " + course.getName() + ".");
        }

        // Watching a video lesson counts as attending that course today,
        // unless an instructor has already recorded attendance for the day.
        if (content.getType() != null && content.getType().toLowerCase().contains("video")) {
            LocalDate today = LocalDate.now();
            if (attendanceRepository.findByCourse_IdAndLearner_IdAndSessionDate(course.getId(), learner.getId(), today).isEmpty()) {
                Attendance a = new Attendance();
                a.setCourse(course);
                a.setLearner(learner);
                a.setSessionDate(today);
                a.setStatus(Attendance.Status.PRESENT);
                a.setSource("AUTO");
                attendanceRepository.save(a);
            }
        }

        activityService.record(learner.getId(), ActivityEvent.Type.VIEW_LESSON, course.getId(),
                "Opened " + content.getTitle());
        return new LessonViewResult(course.getId(), percent, newlyCompleted);
    }
}
