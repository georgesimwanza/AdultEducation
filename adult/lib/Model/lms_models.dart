/// Models for the learning endpoints: profiles, enrollment, assignments,
/// attendance, messages, notifications and reports.
library;

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
int? _int(dynamic v) => v == null ? null : (v as num).toInt();
List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
    (v as List? ?? []).map((e) => f(e as Map<String, dynamic>)).toList();

/// Learner-facing name for a backend role.
String roleLabel(String? role) => switch (role) {
      'USER' => 'Learner',
      'INSTRUCTOR' => 'Instructor',
      'ADMIN' => 'Admin',
      'INSTITUTION' => 'Institution admin',
      _ => role ?? '',
    };

class Profile {
  final int id;
  final String firstName, lastName, email, role;
  final String? phoneNumber, dateOfBirth, gender, address, educationLevel, occupation;
  final String? institutionName, programmeName;
  final bool isActive;
  final DateTime? lastLoginAt;

  Profile.fromJson(Map<String, dynamic> j)
      : id = _int(j['id'])!,
        firstName = j['firstName'] ?? '',
        lastName = j['lastName'] ?? '',
        email = j['email'] ?? '',
        role = j['role'] ?? 'USER',
        phoneNumber = j['phoneNumber'],
        dateOfBirth = j['dateOfBirth'],
        gender = j['gender'],
        address = j['address'],
        educationLevel = j['educationLevel'],
        occupation = j['occupation'],
        institutionName = j['institutionName'],
        programmeName = j['programmeName'],
        isActive = j['isActive'] != false,
        lastLoginAt = _date(j['lastLoginAt']);

  String get fullName => '$firstName $lastName'.trim();
}

class CourseSummary {
  final int id;
  final String courseCode, name;
  final String? description, category, level;
  final int credits, lessonCount, progressPercentage;
  final bool isActive, enrolled;

  CourseSummary.fromJson(Map<String, dynamic> j)
      : id = _int(j['id'])!,
        courseCode = j['courseCode'] ?? '',
        name = j['name'] ?? '',
        description = j['description'],
        category = j['category'],
        level = j['level'],
        credits = _int(j['credits']) ?? 0,
        lessonCount = _int(j['lessonCount']) ?? 0,
        progressPercentage = _int(j['progressPercentage']) ?? 0,
        isActive = j['isActive'] != false,
        enrolled = j['enrolled'] == true;
}

class Enrollment {
  final int courseId;
  final String courseCode, courseName, status;
  final int progressPercentage, lessonsViewed, totalLessons;
  final DateTime? enrolledAt, completedAt, lastAccessed;

  Enrollment.fromJson(Map<String, dynamic> j)
      : courseId = _int(j['courseId'])!,
        courseCode = j['courseCode'] ?? '',
        courseName = j['courseName'] ?? '',
        status = j['status'] ?? 'ACTIVE',
        progressPercentage = _int(j['progressPercentage']) ?? 0,
        lessonsViewed = _int(j['lessonsViewed']) ?? 0,
        totalLessons = _int(j['totalLessons']) ?? 0,
        enrolledAt = _date(j['enrolledAt']),
        completedAt = _date(j['completedAt']),
        lastAccessed = _date(j['lastAccessed']);
}

class Submission {
  final int id, assignmentId, learnerId;
  final String assignmentTitle, learnerName;
  final String? answerText, fileUrl, feedback;
  final int? score, maxScore;
  final DateTime? submittedAt, gradedAt;
  final bool late;

  Submission.fromJson(Map<String, dynamic> j)
      : id = _int(j['id'])!,
        assignmentId = _int(j['assignmentId'])!,
        learnerId = _int(j['learnerId'])!,
        assignmentTitle = j['assignmentTitle'] ?? '',
        learnerName = j['learnerName'] ?? '',
        answerText = j['answerText'],
        fileUrl = j['fileUrl'],
        feedback = j['feedback'],
        score = _int(j['score']),
        maxScore = _int(j['maxScore']),
        submittedAt = _date(j['submittedAt']),
        gradedAt = _date(j['gradedAt']),
        late = j['late'] == true;

  bool get isGraded => gradedAt != null;
}

class Assignment {
  final int id, courseId, maxScore, submissionCount, gradedCount;
  final String courseName, title, kind;
  final String? description;
  final DateTime dueDate;
  final Submission? mySubmission;

  Assignment.fromJson(Map<String, dynamic> j)
      : id = _int(j['id'])!,
        courseId = _int(j['courseId'])!,
        maxScore = _int(j['maxScore']) ?? 100,
        submissionCount = _int(j['submissionCount']) ?? 0,
        gradedCount = _int(j['gradedCount']) ?? 0,
        courseName = j['courseName'] ?? '',
        title = j['title'] ?? '',
        kind = j['kind'] ?? 'ASSIGNMENT',
        description = j['description'],
        dueDate = _date(j['dueDate']) ?? DateTime.now(),
        mySubmission = j['mySubmission'] == null
            ? null
            : Submission.fromJson(j['mySubmission'] as Map<String, dynamic>);

  bool get isTest => kind == 'TEST';
  bool get isOverdue => mySubmission == null && dueDate.isBefore(DateTime.now());
}

class QuizAttempt {
  final int id, quizId;
  final String? quizTitle, courseName, feedback, studentName, studentEmail;
  final int? score;
  final DateTime? submittedAt, gradedAt;

  QuizAttempt.fromJson(Map<String, dynamic> j)
      : id = _int(j['id'])!,
        quizId = _int(j['quizId'])!,
        quizTitle = j['quizTitle'],
        courseName = j['courseName'],
        feedback = j['feedback'],
        studentName = j['studentName'],
        studentEmail = j['studentEmail'],
        score = _int(j['score']),
        submittedAt = _date(j['submittedAt']),
        gradedAt = _date(j['gradedAt']);
}

class AttendanceRecord {
  final int courseId;
  final String courseName, status, source;
  final DateTime date;

  AttendanceRecord.fromJson(Map<String, dynamic> j)
      : courseId = _int(j['courseId'])!,
        courseName = j['courseName'] ?? '',
        status = j['status'] ?? '',
        source = j['source'] ?? 'MANUAL',
        date = _date(j['date']) ?? DateTime.now();
}

class AttendanceSheetEntry {
  final int learnerId;
  final String name;
  String? status;
  final String? source;

  AttendanceSheetEntry.fromJson(Map<String, dynamic> j)
      : learnerId = _int(j['learnerId'])!,
        name = j['name'] ?? '',
        status = j['status'],
        source = j['source'];
}

class Contact {
  final int id;
  final String name, role;

  Contact.fromJson(Map<String, dynamic> j)
      : id = _int(j['id'])!,
        name = j['name'] ?? '',
        role = j['role'] ?? '';
}

class Conversation {
  final int userId, unread;
  final String name, role, lastMessage;
  final DateTime? lastAt;

  Conversation.fromJson(Map<String, dynamic> j)
      : userId = _int(j['userId'])!,
        unread = _int(j['unread']) ?? 0,
        name = j['name'] ?? '',
        role = j['role'] ?? '',
        lastMessage = j['lastMessage'] ?? '',
        lastAt = _date(j['lastAt']);
}

class ChatMessage {
  final int id;
  final String body;
  final bool mine;
  final DateTime sentAt;
  final DateTime? readAt;

  ChatMessage.fromJson(Map<String, dynamic> j)
      : id = _int(j['id'])!,
        body = j['body'] ?? '',
        mine = j['mine'] == true,
        sentAt = _date(j['sentAt']) ?? DateTime.now(),
        readAt = _date(j['readAt']);
}

class AppNotification {
  final int id;
  final String type, title;
  final String? body;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification.fromJson(Map<String, dynamic> j)
      : id = _int(j['id'])!,
        type = j['type'] ?? 'SYSTEM',
        title = j['title'] ?? '',
        body = j['body'],
        createdAt = _date(j['createdAt']) ?? DateTime.now(),
        readAt = _date(j['readAt']);

  bool get isUnread => readAt == null;
}

class GradeLine {
  final String title, kind;
  final String? courseName, feedback;
  final int? score, maxScore, percent;
  final DateTime? date;

  GradeLine.fromJson(Map<String, dynamic> j)
      : title = j['title'] ?? '',
        kind = j['kind'] ?? '',
        courseName = j['courseName'],
        feedback = j['feedback'],
        score = _int(j['score']),
        maxScore = _int(j['maxScore']),
        percent = _int(j['percent']),
        date = _date(j['date']);
}

class CourseProgressLine {
  final int courseId, progressPercentage;
  final String courseName, status;
  final DateTime? completedAt;

  CourseProgressLine.fromJson(Map<String, dynamic> j)
      : courseId = _int(j['courseId'])!,
        progressPercentage = _int(j['progressPercentage']) ?? 0,
        courseName = j['courseName'] ?? '',
        status = j['status'] ?? '',
        completedAt = _date(j['completedAt']);
}

class LearnerReport {
  final int learnerId, averageProgress, completedCourses, activityLast30Days;
  final String name, email;
  final String? educationLevel, programmeName;
  final int? averageQuizScore, averageAssignmentPercent, attendanceRate;
  final DateTime? lastActive, generatedAt;
  final List<CourseProgressLine> courses;
  final List<GradeLine> grades;
  final List<AttendanceRecord> attendance;

  LearnerReport.fromJson(Map<String, dynamic> j)
      : learnerId = _int(j['learnerId'])!,
        averageProgress = _int(j['averageProgress']) ?? 0,
        completedCourses = _int(j['completedCourses']) ?? 0,
        activityLast30Days = _int(j['activityLast30Days']) ?? 0,
        name = j['name'] ?? '',
        email = j['email'] ?? '',
        educationLevel = j['educationLevel'],
        programmeName = j['programmeName'],
        averageQuizScore = _int(j['averageQuizScore']),
        averageAssignmentPercent = _int(j['averageAssignmentPercent']),
        attendanceRate = _int(j['attendanceRate']),
        lastActive = _date(j['lastActive']),
        generatedAt = _date(j['generatedAt']),
        courses = _list(j['courses'], CourseProgressLine.fromJson),
        grades = _list(j['grades'], GradeLine.fromJson),
        attendance = _list(j['attendance'], AttendanceRecord.fromJson);
}

class CourseStats {
  final int courseId, enrolled, completed, completionRate, averageProgress;
  final String courseCode, courseName;
  final int? averageQuizScore, averageAssignmentPercent, attendanceRate;

  CourseStats.fromJson(Map<String, dynamic> j)
      : courseId = _int(j['courseId'])!,
        enrolled = _int(j['enrolled']) ?? 0,
        completed = _int(j['completed']) ?? 0,
        completionRate = _int(j['completionRate']) ?? 0,
        averageProgress = _int(j['averageProgress']) ?? 0,
        courseCode = j['courseCode'] ?? '',
        courseName = j['courseName'] ?? '',
        averageQuizScore = _int(j['averageQuizScore']),
        averageAssignmentPercent = _int(j['averageAssignmentPercent']),
        attendanceRate = _int(j['attendanceRate']);
}

class ParticipationLine {
  final int learnerId, eventsLast30Days, averageProgress;
  final String name, email, status;
  final int? attendanceRate;
  final DateTime? lastActive;

  ParticipationLine.fromJson(Map<String, dynamic> j)
      : learnerId = _int(j['learnerId'])!,
        eventsLast30Days = _int(j['eventsLast30Days']) ?? 0,
        averageProgress = _int(j['averageProgress']) ?? 0,
        name = j['name'] ?? '',
        email = j['email'] ?? '',
        status = j['status'] ?? '',
        attendanceRate = _int(j['attendanceRate']),
        lastActive = _date(j['lastActive']);
}

class AdminDashboardData {
  final int totalLearners, activeLearnersLast7Days, totalInstructors, totalCourses;
  final int totalEnrollments, completionRate, averageProgress, pendingGrading, upcomingDeadlines;
  final List<CourseStats> courses;
  final List<ParticipationLine> learnersNeedingAttention;

  AdminDashboardData.fromJson(Map<String, dynamic> j)
      : totalLearners = _int(j['totalLearners']) ?? 0,
        activeLearnersLast7Days = _int(j['activeLearnersLast7Days']) ?? 0,
        totalInstructors = _int(j['totalInstructors']) ?? 0,
        totalCourses = _int(j['totalCourses']) ?? 0,
        totalEnrollments = _int(j['totalEnrollments']) ?? 0,
        completionRate = _int(j['completionRate']) ?? 0,
        averageProgress = _int(j['averageProgress']) ?? 0,
        pendingGrading = _int(j['pendingGrading']) ?? 0,
        upcomingDeadlines = _int(j['upcomingDeadlines']) ?? 0,
        courses = _list(j['courses'], CourseStats.fromJson),
        learnersNeedingAttention = _list(j['learnersNeedingAttention'], ParticipationLine.fromJson);
}

class LearnerDashboardData {
  final int enrolledCourses, completedCourses, averageProgress;
  final int unreadNotifications, unreadMessages;
  final int? averageQuizScore, attendanceRate;
  final List<Assignment> upcomingDeadlines;
  final List<GradeLine> recentGrades;
  final List<Enrollment> continueLearning;

  LearnerDashboardData.fromJson(Map<String, dynamic> j)
      : enrolledCourses = _int(j['enrolledCourses']) ?? 0,
        completedCourses = _int(j['completedCourses']) ?? 0,
        averageProgress = _int(j['averageProgress']) ?? 0,
        unreadNotifications = _int(j['unreadNotifications']) ?? 0,
        unreadMessages = _int(j['unreadMessages']) ?? 0,
        averageQuizScore = _int(j['averageQuizScore']),
        attendanceRate = _int(j['attendanceRate']),
        upcomingDeadlines = _list(j['upcomingDeadlines'], Assignment.fromJson),
        recentGrades = _list(j['recentGrades'], GradeLine.fromJson),
        continueLearning = _list(j['continueLearning'], Enrollment.fromJson);
}
