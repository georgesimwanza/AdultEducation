package com.project.adult.Controller;


import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.project.adult.DTO.SubjectDTO;
import com.project.adult.Model.Course;
import com.project.adult.Service.SubjectService;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("api/subject")
public class SubjectController {
    final SubjectService subjectService;

    public SubjectController(SubjectService subjectService) {
        this.subjectService = subjectService;
    }
    @JsonIgnoreProperties("course")
    @GetMapping("/programme/{programmeId}")
    public ResponseEntity<List<SubjectDTO>> getProgrammeSubjects(
            @PathVariable Long programmeId
    ){
        return ResponseEntity.ok(subjectService.getAlldetailsById(programmeId));
    }


    @GetMapping("/allSubjects")
    @JsonIgnoreProperties("course")
 public List<Course> getAllsubjects(){
        return subjectService.getAllSubjects();
 }
}
