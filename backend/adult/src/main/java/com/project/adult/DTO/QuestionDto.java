package com.project.adult.DTO;

import com.fasterxml.jackson.annotation.JsonSubTypes;
import com.fasterxml.jackson.annotation.JsonTypeInfo;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Mirrors the sealed Question class on the Flutter side field-for-field.
 * The "type" values below ("multipleChoice", "trueFalse", "shortAnswer",
 * "essay") must exactly match QuestionType.values[].name on the Dart side
 * — that's what QuestionEditorDispatcher / Question.fromJson switch on.
 */
@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, include = JsonTypeInfo.As.EXISTING_PROPERTY, property = "type", visible = true)
@JsonSubTypes({
        @JsonSubTypes.Type(value = MultipleChoiceQuestionDto.class, name = "multipleChoice"),
        @JsonSubTypes.Type(value = TrueFalseQuestionDto.class, name = "trueFalse"),
        @JsonSubTypes.Type(value = ShortAnswerQuestionDto.class, name = "shortAnswer"),
        @JsonSubTypes.Type(value = EssayQuestionDto.class, name = "essay"),
})
@Data
@AllArgsConstructor
@NoArgsConstructor
public abstract class QuestionDto {

    private String id;
    private String type;
    private String text;
    private int points = 1;
    private String explanation;

}
