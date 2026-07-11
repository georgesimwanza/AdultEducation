package com.project.adult.Service;

import com.project.adult.DTO.CreateQuizRequest;
import com.project.adult.DTO.QuizDto;
import com.project.adult.Model.Quiz;
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

    public QuizService(QuizRepository quizRepository) {
        this.quizRepository = quizRepository;
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
            quizzes = quizRepository.findBySubjectIdAndInstitutionId(subjectId, institutionId);
        } else if (subjectId != null) {
            quizzes = quizRepository.findBySubjectId(subjectId);
        } else if (institutionId != null) {
            quizzes = quizRepository.findByInstitutionId(institutionId);
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
        Quiz quiz = new Quiz(
                request.getTitle(),
                request.getDescription(),
                request.getSubjectId(),
                request.getInstitutionId()
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
        quiz.setSubjectId(dto.getSubjectId());
        quiz.setInstitutionId(dto.getInstitutionId());
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
