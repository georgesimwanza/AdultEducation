package com.project.adult.Service;

import com.project.adult.DTO.CreateQuizRequest;
import com.project.adult.DTO.QuizDto;
import com.project.adult.Model.Course;
import com.project.adult.Model.Institution;
import com.project.adult.Model.Quiz;
import com.project.adult.Repository.CourseRepository;
import com.project.adult.Repository.InstitutionRepository;
import com.project.adult.Utilities.QuizMapper;
import com.project.adult.Repository.QuizRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class QuizService {

    private final QuizRepository quizRepository;
    private final CourseRepository courseRepository;
    private final InstitutionRepository institutionRepository;

    public QuizService(QuizRepository quizRepository, CourseRepository courseRepository, InstitutionRepository institutionRepository) {
        this.quizRepository = quizRepository;
        this.courseRepository = courseRepository;
        this.institutionRepository = institutionRepository;
    }

    /**
     * Used by both the teacher's admin list and the student's quiz list.
     * Pass subjectId and/or institutionId to scope results — e.g. a
     * student's quiz list would filter by both.
     */
    @Transactional(readOnly = true)
    public List<QuizDto> getAllQuizzes(Long subjectId, Long institutionId) {
        List<Quiz> quizzes;
        if (subjectId != null && institutionId != null) {
            quizzes = quizRepository.findByCourse_IdAndInstitution_Id(subjectId, institutionId);
        } else if (subjectId != null) {
            quizzes = quizRepository.findByCourse_Id(subjectId);
        } else if (institutionId != null) {
            quizzes = quizRepository.findByInstitution_Id(institutionId);
        } else {
            quizzes = quizRepository.findAll();
        }
        return quizzes.stream().map(QuizMapper::toDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public QuizDto getQuiz(Long id) {
        Quiz quiz = quizRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Quiz " + id + " not found"));
        return QuizMapper.toDto(quiz);
    }

    @Transactional
    public QuizDto createQuiz(CreateQuizRequest request) {
        Course course = courseRepository.findById(request.getCourseId())
                .orElseThrow(() -> new EntityNotFoundException("Course not found"));

        Institution institution = institutionRepository.findById(request.getInstitutionId())
                .orElseThrow(() -> new EntityNotFoundException("Institution not found"));

        Quiz quiz = new Quiz();

        quiz.setTitle(request.getTitle());
        quiz.setDescription(request.getDescription());
        quiz.setCourse(course);
        quiz.setInstitution(institution);
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
     */
    @Transactional
    public QuizDto updateQuiz(Long id, QuizDto dto) {
        Quiz quiz = quizRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Quiz " + id + " not found"));

        quiz.setTitle(dto.getTitle());
        quiz.setDescription(dto.getDescription());

        Course course = courseRepository.findById(dto.getCourseId())
                .orElseThrow(() -> new EntityNotFoundException("Course not found"));

        Institution institution = institutionRepository.findById(dto.getInstitutionId())
                .orElseThrow(() -> new EntityNotFoundException("Institution not found"));

        quiz.setCourse(course);
        quiz.setInstitution(institution);
        quiz.setTimeLimitMinutes(dto.getTimeLimitMinutes());
        quiz.setPassingScorePercent(dto.getPassingScorePercent());

        // orphanRemoval=true on Quiz.questions means clearing + re-adding
        // deletes questions that were removed and inserts new/edited ones,
        // in one transaction.
        quiz.getQuestions().clear();
        quiz.getQuestions().addAll(QuizMapper.toEntities(dto.getQuestions(), quiz));

        Quiz saved = quizRepository.save(quiz);
        return QuizMapper.toDto(saved);
    }

    @Transactional
    public void deleteQuiz(Long id) {
        if (!quizRepository.existsById(id)) {
            throw new EntityNotFoundException("Quiz " + id + " not found");
        }
        quizRepository.deleteById(id);
    }
}