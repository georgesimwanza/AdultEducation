package com.project.adult.DTO;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Request and response shapes for profiles, user management, enrollment,
 * progress, assessment, attendance, messaging and reports. Entities are
 * never returned directly from these endpoints, so lazy relations and
 * personal fields (e.g. password hashes) can't leak into JSON.
 */
public final class LearningDtos {

    private LearningDtos() {
    }

    // ── Profiles & user management ───────────────────────────────────

    public record ProfileDto(Long id, String firstName, String lastName, String email, String role,
                             String phoneNumber, String dateOfBirth, String gender, String address,
                             String educationLevel, String occupation,
                             Long institutionId, String institutionName,
                             Long programmeId, String programmeName,
                             Boolean isActive, LocalDateTime createdAt, LocalDateTime lastLoginAt) {
    }

    public record ProfileUpdateRequest(String firstName, String lastName, String phoneNumber,
                                       String dateOfBirth, String gender, String address,
                                       String educationLevel, String occupation) {
    }

    public record CreateUserRequest(String firstName, String lastName, String email, String password,
                                    String role, Long programmeId, String educationLevel) {
    }

    public record RoleUpdateRequest(String role) {
    }

    public record StatusUpdateRequest(Boolean active) {
    }

    // ── Courses, enrollment & progress ───────────────────────────────

    public record CourseRequest(String courseCode, String name, String description, String category,
                                String level, Integer credits, Integer hoursPerWeek,
                                Boolean isMandatory, Long programmeId) {
    }

    public record CourseSummary(Long id, String courseCode, String name, String description,
                                String category, String level, Integer credits, Boolean isActive,
                                long lessonCount, boolean enrolled, int progressPercentage) {
    }

    public record EnrollmentDto(Long id, Long courseId, String courseCode, String courseName,
                                String status, LocalDateTime enrolledAt, LocalDateTime completedAt,
                                int progressPercentage, long lessonsViewed, long totalLessons,
                                LocalDateTime lastAccessed) {
    }

    public record RosterEntry(Long learnerId, String name, String email, String status,
                              int progressPercentage, LocalDateTime enrolledAt) {
    }

    public record LessonViewResult(Long courseId, int progressPercentage, boolean courseCompleted) {
    }

    // ── Assignments & grading ────────────────────────────────────────

    public record AssignmentRequest(Long courseId, String title, String description, String kind,
                                    LocalDateTime dueDate, Integer maxScore) {
    }

    public record AssignmentDto(Long id, Long courseId, String courseName, String title,
                                String description, String kind, LocalDateTime dueDate,
                                Integer maxScore, LocalDateTime createdAt,
                                long submissionCount, long gradedCount, SubmissionDto mySubmission) {
    }

    public record SubmitRequest(String answerText, String fileUrl) {
    }

    public record GradeRequest(Integer score, String feedback) {
    }

    public record SubmissionDto(Long id, Long assignmentId, String assignmentTitle,
                                Long learnerId, String learnerName,
                                String answerText, String fileUrl, LocalDateTime submittedAt,
                                Integer score, Integer maxScore, String feedback,
                                LocalDateTime gradedAt, boolean late) {
    }

    public record QuizSubmissionDto(Long id, Long quizId, String quizTitle, String courseName,
                                    String studentEmail, String studentName, Integer score,
                                    String feedback, LocalDateTime submittedAt,
                                    LocalDateTime gradedAt, String answersJson) {
    }

    // ── Attendance ───────────────────────────────────────────────────

    public record AttendanceMark(Long learnerId, String status) {
    }

    public record AttendanceMarkRequest(Long courseId, LocalDate date, List<AttendanceMark> entries) {
    }

    public record AttendanceSheetEntry(Long learnerId, String name, String status, String source) {
    }

    public record AttendanceRecordDto(Long id, Long courseId, String courseName, LocalDate date,
                                      String status, String source) {
    }

    // ── Messaging ────────────────────────────────────────────────────

    public record ContactDto(Long id, String name, String role) {
    }

    public record SendMessageRequest(Long recipientId, String body) {
    }

    public record MessageDto(Long id, Long senderId, String senderName, Long recipientId,
                             String recipientName, String body, LocalDateTime sentAt,
                             LocalDateTime readAt, boolean mine) {
    }

    public record ConversationDto(Long userId, String name, String role, String lastMessage,
                                  LocalDateTime lastAt, long unread) {
    }

    // ── Reports & dashboards ─────────────────────────────────────────

    public record CourseProgressLine(Long courseId, String courseName, String status,
                                     int progressPercentage, LocalDateTime completedAt) {
    }

    public record GradeLine(String title, String courseName, String kind, Integer score,
                            Integer maxScore, Integer percent, String feedback, LocalDateTime date) {
    }

    public record LearnerReport(Long learnerId, String name, String email, String educationLevel,
                                String programmeName, LocalDateTime generatedAt,
                                List<CourseProgressLine> courses, int averageProgress,
                                int completedCourses, Integer averageQuizScore,
                                Integer averageAssignmentPercent, Integer attendanceRate,
                                long activityLast30Days, LocalDateTime lastActive,
                                List<GradeLine> grades, List<AttendanceRecordDto> attendance) {
    }

    public record CourseStats(Long courseId, String courseCode, String courseName, long enrolled,
                              long completed, int completionRate, int averageProgress,
                              Integer averageQuizScore, Integer averageAssignmentPercent,
                              Integer attendanceRate) {
    }

    public record ParticipationLine(Long learnerId, String name, String email,
                                    long eventsLast30Days, LocalDateTime lastActive,
                                    Integer attendanceRate, int averageProgress, String status) {
    }

    public record AdminDashboard(long totalLearners, long activeLearnersLast7Days,
                                 long totalInstructors, long totalCourses, long totalEnrollments,
                                 int completionRate, int averageProgress, long pendingGrading,
                                 long upcomingDeadlines, List<CourseStats> courses,
                                 List<ParticipationLine> learnersNeedingAttention) {
    }

    public record LearnerDashboard(long enrolledCourses, long completedCourses, int averageProgress,
                                   Integer averageQuizScore, Integer attendanceRate,
                                   long unreadNotifications, long unreadMessages,
                                   List<AssignmentDto> upcomingDeadlines,
                                   List<GradeLine> recentGrades,
                                   List<EnrollmentDto> continueLearning) {
    }
}
