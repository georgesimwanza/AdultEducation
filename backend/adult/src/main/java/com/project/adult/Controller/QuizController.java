package com.project.adult.Controller;

import com.project.adult.DTO.CreateQuizRequest;
import com.project.adult.DTO.QuizDto;
import com.project.adult.Service.QuizService;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/quizzes")
public class QuizController {

    private final QuizService quizService;

    public QuizController(QuizService quizService) {
        this.quizService = quizService;
    }

    /** Both the teacher's admin list and the student's quiz list hit this. */
    @GetMapping
    public List<QuizDto> getAllQuizzes(
            @RequestParam(required = false) Long courseId,
            @RequestParam(required = false) Long institutionId
    ) {
        return quizService.getAllQuizzes(courseId, institutionId);
    }

    @GetMapping("/{id}")
    public QuizDto getQuiz(@PathVariable Long id) {
        return quizService.getQuiz(id);
    }

    // TODO: once this module is behind your JWT/role setup, restrict
    // create/update/delete to teacher/admin, e.g.
    // @PreAuthorize("hasRole('TEACHER')")
    @PostMapping
    public ResponseEntity<QuizDto> createQuiz(@RequestBody CreateQuizRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(quizService.createQuiz(request));
    }

    @PutMapping("/{id}")
    public QuizDto updateQuiz(@PathVariable Long id, @RequestBody QuizDto dto) {
        return quizService.updateQuiz(id, dto);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteQuiz(@PathVariable Long id) {
        quizService.deleteQuiz(id);
        return ResponseEntity.noContent().build();
    }

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<String> handleNotFound(EntityNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(ex.getMessage());
    }
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> handleBadRequest(IllegalArgumentException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ex.getMessage());
    }
}
