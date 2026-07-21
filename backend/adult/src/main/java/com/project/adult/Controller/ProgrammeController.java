package com.project.adult.Controller;

import com.project.adult.Service.ProgrammeService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.project.adult.DTO.ProgrammeDTO;

import java.util.List;

// ProgrammeController.java
@RestController
@RequestMapping("/api/programmes")
@RequiredArgsConstructor
public class ProgrammeController {

    private final ProgrammeService programmeService;

    @GetMapping("/allProgrammes")
    public ResponseEntity<List<ProgrammeDTO>> getAllProgrammes() {
        return ResponseEntity.ok(programmeService.getAllProgrammes());
    }
    @GetMapping("/{id}/title")
    public ResponseEntity<String> getProgrammeTitle(@PathVariable Long id) {
        return ResponseEntity.ok(programmeService.getTitleById(id));
    }
}