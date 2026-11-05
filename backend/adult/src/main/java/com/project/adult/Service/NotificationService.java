package com.project.adult.Service;

import com.project.adult.Model.Assignment;
import com.project.adult.Model.Enrollment;
import com.project.adult.Model.Notification;
import com.project.adult.Repository.AssignmentRepository;
import com.project.adult.Repository.AssignmentSubmissionRepository;
import com.project.adult.Repository.EnrollmentRepository;
import com.project.adult.Repository.NotificationRepository;
import jakarta.transaction.Transactional;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collection;
import java.util.List;

/**
 * In-app notifications: deadlines, grades, announcements and messages.
 * Also runs the hourly job that reminds learners of work due within 24 hours.
 */
@Service
public class NotificationService {

    private static final DateTimeFormatter DUE_FORMAT = DateTimeFormatter.ofPattern("EEE d MMM, HH:mm");

    private final NotificationRepository repository;
    private final AssignmentRepository assignmentRepository;
    private final AssignmentSubmissionRepository submissionRepository;
    private final EnrollmentRepository enrollmentRepository;

    public NotificationService(NotificationRepository repository,
                               AssignmentRepository assignmentRepository,
                               AssignmentSubmissionRepository submissionRepository,
                               EnrollmentRepository enrollmentRepository) {
        this.repository = repository;
        this.assignmentRepository = assignmentRepository;
        this.submissionRepository = submissionRepository;
        this.enrollmentRepository = enrollmentRepository;
    }

    public void notify(Long userId, Notification.Type type, String title, String body) {
        if (userId == null) return;
        Notification n = new Notification();
        n.setUserId(userId);
        n.setType(type);
        n.setTitle(title.length() > 255 ? title.substring(0, 255) : title);
        n.setBody(body != null && body.length() > 1000 ? body.substring(0, 1000) : body);
        repository.save(n);
    }

    public void notifyAll(Collection<Long> userIds, Notification.Type type, String title, String body) {
        userIds.stream().distinct().forEach(id -> notify(id, type, title, body));
    }

    public List<Notification> list(Long userId, int limit) {
        return repository.findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(0, Math.min(limit, 200)));
    }

    public long unreadCount(Long userId) {
        return repository.countByUserIdAndReadAtIsNull(userId);
    }

    @Transactional
    public void markRead(Long userId, Long notificationId) {
        Notification n = repository.findById(notificationId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Notification not found"));
        if (!n.getUserId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Notification not found");
        }
        if (n.getReadAt() == null) {
            n.setReadAt(LocalDateTime.now());
            repository.save(n);
        }
    }

    @Transactional
    public void markAllRead(Long userId) {
        repository.markAllRead(userId, LocalDateTime.now());
    }

    /** Tells every enrolled learner that new work has been set. */
    public void announceNewAssignment(Assignment a) {
        List<Long> learners = enrollmentRepository.findActiveByCourseWithUser(a.getCourse().getId())
                .stream().map(e -> e.getUser().getId()).toList();
        String kind = "TEST".equalsIgnoreCase(a.getKind()) ? "test" : "assignment";
        notifyAll(learners, Notification.Type.DEADLINE,
                "New " + kind + ": " + a.getTitle(),
                a.getCourse().getName() + " — due " + a.getDueDate().format(DUE_FORMAT));
    }

    /**
     * Hourly: for work due in the next 24 hours, remind each enrolled learner
     * who has not submitted yet. Each assignment is reminded once.
     */
    @Scheduled(cron = "0 0 * * * *")
    @Transactional
    public void sendDeadlineReminders() {
        LocalDateTime now = LocalDateTime.now();
        for (Assignment a : assignmentRepository.findDueBetweenWithoutReminder(now, now.plusHours(24))) {
            for (Enrollment e : enrollmentRepository.findActiveByCourseWithUser(a.getCourse().getId())) {
                Long learnerId = e.getUser().getId();
                boolean submitted = submissionRepository
                        .findByAssignment_IdAndLearner_Id(a.getId(), learnerId).isPresent();
                if (!submitted) {
                    notify(learnerId, Notification.Type.DEADLINE,
                            "Due soon: " + a.getTitle(),
                            a.getCourse().getName() + " — due " + a.getDueDate().format(DUE_FORMAT)
                                    + ". You have not submitted yet.");
                }
            }
            a.setReminderSent(true);
            assignmentRepository.save(a);
        }
    }
}
