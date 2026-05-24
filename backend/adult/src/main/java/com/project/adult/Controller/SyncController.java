package com.project.adult.Controller;

import com.project.adult.DTO.ContentDTO;
import com.project.adult.DTO.SubjectDTO;
import com.project.adult.Service.SyncService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sync")
public class SyncController {

    private final SyncService syncService;

    public SyncController(SyncService syncService) {
        this.syncService = syncService;
    }

    @GetMapping("/subjects")
    public ResponseEntity<List<SubjectDTO>> syncSubjects(
            @RequestParam(required = false) Long since) {
        return ResponseEntity.ok(syncService.getSyncedSubjects(since));
    }

    @GetMapping("/content")
    public ResponseEntity<List<ContentDTO>> syncContent(
            @RequestParam(required = false) Long since) {
        return ResponseEntity.ok(syncService.getSyncedContent(since));
    }
}