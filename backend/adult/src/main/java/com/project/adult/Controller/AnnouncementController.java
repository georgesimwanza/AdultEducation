package com.project.adult.Controller;

import com.project.adult.Model.Announcement;
import com.project.adult.Security.UserPrincipal;
import com.project.adult.Service.AnnouncementService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/announcement")
@RequiredArgsConstructor
public class AnnouncementController {

    private final AnnouncementService announcementService;

    @GetMapping("/allAnnouncements")
    public ResponseEntity<List<Announcement>> getAll() {
        return ResponseEntity.ok(announcementService.getAll());
    }

    @PostMapping("/addAnnouncement")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Announcement> create(@RequestBody Map<String, Object> body, Authentication auth) {
        UserPrincipal principal = (UserPrincipal) auth.getPrincipal();
        Long institutionId = principal.getInstitutionId();

        if (institutionId == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .build(); // admin account has no institution attached — shouldn't normally happen
        }

        Announcement announcement = announcementService.createFromRequest(
                (String) body.get("title"),
                (String) body.get("content"),
                (Long) body.get("programmeId"),
                institutionId.longValue()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(announcement);
    }

    @DeleteMapping("/delete/{id}")

    public ResponseEntity<Void> delete(@PathVariable int id) {
        announcementService.delete(id);
        return ResponseEntity.noContent().build();
    }
}