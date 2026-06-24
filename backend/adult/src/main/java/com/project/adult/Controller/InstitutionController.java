package com.project.adult.Controller;


import com.project.adult.DTO.InstitutionDto;
import com.project.adult.Model.Institution;
import com.project.adult.Service.institutionService;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("api/institution")
public class InstitutionController {
    private final institutionService institutionService;

    public InstitutionController(institutionService institutionService) {
        this.institutionService = institutionService;
    }

    @PostMapping("/register")
    public ResponseEntity<?> registerInstitution(@RequestBody Institution institution) {
        try {
            Institution saved = institutionService.registerInstitution(institution);
            return ResponseEntity.status(201).body(saved);
        } catch (RuntimeException e) {
            return ResponseEntity.status(409).body(e.getMessage());
        }
    }
    @GetMapping("/institutions")
    public ResponseEntity<List<InstitutionDto>> getInstitutions() {
        return ResponseEntity.ok(institutionService.getInstitutions());
    }


}
