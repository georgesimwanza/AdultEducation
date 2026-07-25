package com.project.adult.Utilities;

import com.project.adult.DTO.EssayQuestionDto;
import com.project.adult.DTO.MultipleChoiceQuestionDto;
import com.project.adult.DTO.QuestionDto;
import com.project.adult.DTO.QuizDto;
import com.project.adult.DTO.ShortAnswerQuestionDto;
import com.project.adult.DTO.TrueFalseQuestionDto;
import com.project.adult.Model.EssayQuestion;
import com.project.adult.Model.MultipleChoiceQuestion;
import com.project.adult.Model.Question;
import com.project.adult.Model.Quiz;
import com.project.adult.Model.ShortAnswerQuestion;
import com.project.adult.Model.TrueFalseQuestion;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Converts between JPA entities and API DTOs. Entities are never handed
 * to Jackson directly — every response goes through here first — which
 * is what keeps the bidirectional Quiz <-> Question relationship from
 * causing the infinite-recursion problem you've run into elsewhere.
 */
public final class QuizMapper {

    private QuizMapper() {
    }

    public static QuizDto toDto(Quiz quiz) {
        QuizDto dto = new QuizDto();
        dto.setId(String.valueOf(quiz.getId()));
        dto.setTitle(quiz.getTitle());
        dto.setDescription(quiz.getDescription());
        dto.setCourseId(quiz.getCourse().getId());
        dto.setInstitutionId(quiz.getInstitution().getId()
        );
        dto.setTimeLimitMinutes(quiz.getTimeLimitMinutes());
        dto.setPassingScorePercent(quiz.getPassingScorePercent());
        dto.setQuestions(quiz.getQuestions().stream()
                .map(QuizMapper::toDto)
                .collect(Collectors.toList()));
        return dto;
    }

    public static QuestionDto toDto(Question question) {
        if (question instanceof MultipleChoiceQuestion mcq) {
            MultipleChoiceQuestionDto dto = new MultipleChoiceQuestionDto();
            fillBase(dto, mcq);
            dto.setOptions(mcq.getOptions());
            dto.setCorrectOptionIndex(mcq.getCorrectOptionIndex());
            return dto;
        } else if (question instanceof TrueFalseQuestion tf) {
            TrueFalseQuestionDto dto = new TrueFalseQuestionDto();
            fillBase(dto, tf);
            dto.setCorrectAnswer(tf.isCorrectAnswer());
            return dto;
        } else if (question instanceof ShortAnswerQuestion sa) {
            ShortAnswerQuestionDto dto = new ShortAnswerQuestionDto();
            fillBase(dto, sa);
            dto.setAcceptedAnswers(sa.getAcceptedAnswers());
            dto.setCaseSensitive(sa.isCaseSensitive());
            return dto;
        } else if (question instanceof EssayQuestion essay) {
            EssayQuestionDto dto = new EssayQuestionDto();
            fillBase(dto, essay);
            dto.setMinWords(essay.getMinWords());
            dto.setMaxWords(essay.getMaxWords());
            dto.setRubric(essay.getRubric());
            return dto;
        }
        throw new IllegalStateException("Unknown question entity type: " + question.getClass());
    }

    private static void fillBase(QuestionDto dto, Question entity) {
        dto.setId(entity.getId() == null ? null : String.valueOf(entity.getId()));
        dto.setText(entity.getText());
        dto.setPoints(entity.getPoints());
        dto.setExplanation(entity.getExplanation());
    }

    /** Builds a brand-new Question entity (no id yet) from a DTO. */
    public static Question toEntity(QuestionDto dto) {
        if (dto instanceof MultipleChoiceQuestionDto mcq) {
            return new MultipleChoiceQuestion(mcq.getText(), mcq.getPoints(), mcq.getExplanation(),
                    mcq.getOptions(), mcq.getCorrectOptionIndex());
        } else if (dto instanceof TrueFalseQuestionDto tf) {
            return new TrueFalseQuestion(tf.getText(), tf.getPoints(), tf.getExplanation(),
                    tf.isCorrectAnswer());
        } else if (dto instanceof ShortAnswerQuestionDto sa) {
            return new ShortAnswerQuestion(sa.getText(), sa.getPoints(), sa.getExplanation(),
                    sa.getAcceptedAnswers(), sa.isCaseSensitive());
        } else if (dto instanceof EssayQuestionDto essay) {
            return new EssayQuestion(essay.getText(), essay.getPoints(), essay.getExplanation(),
                    essay.getMinWords(), essay.getMaxWords(), essay.getRubric());
        }
        throw new IllegalStateException("Unknown question DTO type: " + dto.getClass());
    }

    public static List<Question> toEntities(List<QuestionDto> dtos, Quiz owner) {
        return dtos.stream().map(d -> {
            Question q = toEntity(d);
            q.setQuiz(owner);
            return q;
        }).collect(Collectors.toList());
    }
}
