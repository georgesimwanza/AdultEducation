package com.project.adult.Service;

import com.project.adult.DTO.CreateQuizRequest;
import com.project.adult.DTO.QuestionDto;
import com.project.adult.DTO.QuizDto;
import com.project.adult.Model.Course;
import com.project.adult.Model.Institution;
import com.project.adult.Model.Programme;
import com.project.adult.Model.Question;
import com.project.adult.Model.Quiz;
import com.project.adult.Repository.CourseRepository;
import com.project.adult.Repository.InstitutionRepository;
import com.project.adult.Repository.ProgrammeRepository;
import com.project.adult.Utilities.QuizMapper;
import com.project.adult.Repository.QuizRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Service layer for managing {@link Quiz} entities, including their
 * nested {@link Question} lists.
 * <p>
 * Handles quiz creation, scoped retrieval (by course, institution, and/or
 * programme), and full quiz updates that replace both metadata and questions
 * in a single transaction.
 */
@Service
public class QuizService {

    private final QuizRepository quizRepository;
    private final CourseRepository courseRepository;
    private final InstitutionRepository institutionRepository;
    private final ProgrammeRepository programmeRepository;

    /**
     * Constructs the service with its required repositories.
     *
     * @param quizRepository        repository for persisting and querying quizzes
     * @param courseRepository      repository for looking up the associated course
     * @param institutionRepository repository for looking up the associated institution
     * @param programmeRepository   repository for looking up the associated programme
     */
    public QuizService(QuizRepository quizRepository, CourseRepository courseRepository,
                       InstitutionRepository institutionRepository, ProgrammeRepository programmeRepository) {
        this.quizRepository = quizRepository;
        this.courseRepository = courseRepository;
        this.institutionRepository = institutionRepository;
        this.programmeRepository = programmeRepository;
    }

    /**
     * Retrieves quizzes, optionally scoped by any combination of subject
     * (course), institution, and programme.
     * <p>
     * Used by both the teacher's admin list and the student's quiz list.
     * Pass subjectId, institutionId, and/or programmeId to scope results —
     * e.g. a student's Assignments tab filters by programme and course.
     *
     * @param subjectId     the course/subject id to filter by, or {@code null} for no filter
     * @param institutionId the institution id to filter by, or {@code null} for no filter
     * @param programmeId   the programme id to filter by, or {@code null} for no filter
     * @return a list of {@link QuizDto} matching the given filters, or all quizzes if none are given
     */
    @Transactional(readOnly = true)
    public List<QuizDto> getAllQuizzes(Long subjectId, Long institutionId, Long programmeId) {
        List<Quiz> quizzes;
        if (subjectId != null && institutionId != null && programmeId != null) {
            quizzes = quizRepository.findByProgramme_IdAndCourse_IdAndInstitution_Id(programmeId, subjectId, institutionId);
        } else if (subjectId != null && institutionId != null) {
            quizzes = quizRepository.findByCourse_IdAndInstitution_Id(subjectId, institutionId);
        } else if (programmeId != null) {
            quizzes = quizRepository.findByProgramme_Id(programmeId);
        } else if (subjectId != null) {
            quizzes = quizRepository.findByCourse_Id(subjectId);
        } else if (institutionId != null) {
            quizzes = quizRepository.findByInstitution_Id(institutionId);
        } else {
            quizzes = quizRepository.findAll();
        }
        return quizzes.stream().map(QuizMapper::toDto).collect(Collectors.toList());
    }

    /**
     * Retrieves a single quiz by its identifier.
     *
     * @param id the quiz id
     * @return the matching quiz as a {@link QuizDto}
     * @throws EntityNotFoundException if no quiz exists with the given id
     */
    @Transactional(readOnly = true)
    public QuizDto getQuiz(Long id) {
        Quiz quiz = quizRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Quiz " + id + " not found"));
        return QuizMapper.toDto(quiz);
    }

    /**
     * Creates a new quiz from a request payload, resolving and attaching its
     * course, institution, and programme.
     *
     * @param request the quiz creation request, including course/institution/programme ids
     * @return the saved quiz as a {@link QuizDto}
     * @throws EntityNotFoundException if the referenced course, institution, or programme does not exist
     */
    @Transactional
    public QuizDto createQuiz(CreateQuizRequest request) {
        Course course = courseRepository.findById(request.getCourseId())
                .orElseThrow(() -> new EntityNotFoundException("Course not found"));

        Institution institution = institutionRepository.findById(request.getInstitutionId())
                .orElseThrow(() -> new EntityNotFoundException("Institution not found"));

        Programme programme = programmeRepository.findById(request.getProgrammeId())
                .orElseThrow(() -> new EntityNotFoundException("Programme not found"));

        Quiz quiz = new Quiz();

        quiz.setTitle(request.getTitle());
        quiz.setDescription(request.getDescription());
        quiz.setCourse(course);
        quiz.setInstitution(institution);
        quiz.setProgramme(programme);
        quiz.setTimeLimitMinutes(request.getTimeLimitMinutes());

        // Lombok's @AllArgsConstructor on CreateQuizRequest can end up being
        // the constructor Jackson uses to deserialize (Spring Boot registers
        // ParameterNamesModule by default), and that constructor assigns
        // `null` for any field missing from the JSON body — bypassing the
        // "= 50" field-initializer default entirely. Guard explicitly here
        // rather than trusting the DTO's default to survive deserialization.
        quiz.setPassingScorePercent(
                request.getPassingScorePercent() != null ? request.getPassingScorePercent() : 50
        );

        Quiz saved = quizRepository.save(quiz);

        return QuizMapper.toDto(saved);
    }

    /**
     * Replaces a quiz's metadata and its entire question list in one call.
     * This matches how the Flutter admin screen sends updates: it always
     * builds a full, updated Quiz (settings + complete question list)
     * rather than sending granular per-field patches.
     * <p>
     * Existing questions (identified by a numeric id already present in the
     * database) are updated in place; questions with a non-numeric,
     * client-generated temporary id are treated as new and inserted.
     *
     * @param id  the id of the quiz to update
     * @param dto the full replacement quiz data, including its question list
     * @return the updated quiz as a {@link QuizDto}
     * @throws EntityNotFoundException if the quiz, course, institution, or programme does not exist
     * @throws IllegalArgumentException if any question in the payload has blank text
     */
    @Transactional
    public QuizDto updateQuiz(Long id, QuizDto dto) {
        Quiz quiz = quizRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Quiz " + id + " not found"));

        // NEW: validation guard — right after fetching, before anything else
        for (QuestionDto qDto : dto.getQuestions()) {
            if (qDto.getText() == null || qDto.getText().isBlank()) {
                throw new IllegalArgumentException("Question text cannot be empty");
            }
        }

        quiz.setTitle(dto.getTitle());
        quiz.setDescription(dto.getDescription());

        Course course = courseRepository.findById(dto.getCourseId())
                .orElseThrow(() -> new EntityNotFoundException("Course not found"));

        Institution institution = institutionRepository.findById(dto.getInstitutionId())
                .orElseThrow(() -> new EntityNotFoundException("Institution not found"));

        Programme programme = programmeRepository.findById(dto.getProgrammeId())
                .orElseThrow(() -> new EntityNotFoundException("Programme not found"));

        quiz.setCourse(course);
        quiz.setInstitution(institution);
        quiz.setProgramme(programme);
        quiz.setTimeLimitMinutes(dto.getTimeLimitMinutes());
        quiz.setPassingScorePercent(dto.getPassingScorePercent());


        Map<Long, Question> existingById = quiz.getQuestions().stream()
                .filter(q -> q.getId() != null)
                .collect(Collectors.toMap(Question::getId, q -> q));

        List<Question> updatedQuestions = new ArrayList<>();
        for (QuestionDto qDto : dto.getQuestions()) {
            Long qId = null;
            if (qDto.getId() != null) {
                try {
                    qId = Long.valueOf(qDto.getId());
                } catch (NumberFormatException ex) {
                    // client-generated temp id (e.g. "mcq_1785088627968133") for a
                    // question that hasn't been persisted yet — treat as new
                    qId = null;
                }
            }

            if (qId != null && existingById.containsKey(qId)) {
                Question existing = existingById.get(qId);
                QuizMapper.updateEntity(existing, qDto);
                updatedQuestions.add(existing);
            } else {
                updatedQuestions.add(QuizMapper.toEntity(qDto, quiz));
            }
        }

        quiz.getQuestions().clear();
        quiz.getQuestions().addAll(updatedQuestions);

        Quiz saved = quizRepository.save(quiz);
        return QuizMapper.toDto(saved);
    }

    /**
     * Deletes a quiz by its identifier.
     *
     * @param id the id of the quiz to delete
     * @throws EntityNotFoundException if no quiz exists with the given id
     */
    @Transactional
    public void deleteQuiz(Long id) {
        if (!quizRepository.existsById(id)) {
            throw new EntityNotFoundException("Quiz " + id + " not found");
        }
        quizRepository.deleteById(id);
    }
}