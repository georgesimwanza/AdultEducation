package com.project.adult.Controller;

import com.project.adult.Model.Announcement;
import com.project.adult.Model.Notification;
import com.project.adult.Model.User;
import com.project.adult.Repository.UserRepository;
import com.project.adult.Security.UserPrincipal;
import com.project.adult.Service.AnnouncementService;
import com.project.adult.Service.NotificationService;
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
    private final NotificationService notificationService;
    private final UserRepository userRepository;

    @GetMapping("/allAnnouncements")
    public ResponseEntity<List<Announcement>> getAll() {
        return ResponseEntity.ok(announcementService.getAll());
    }

    @PostMapping("/addAnnouncement")
    @PreAuthorize("hasAnyRole('ADMIN','INSTRUCTOR','INSTITUTION')")
    public ResponseEntity<Announcement> create(@RequestBody Map<String, Object> body, Authentication auth) {
        UserPrincipal principal = (UserPrincipal) auth.getPrincipal();
        Long institutionId = principal.getInstitutionId();

        if (institutionId == null) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .build(); // admin account has no institution attached — shouldn't normally happen
        }
        Long programmeId = ((Number) body.get("programmeId")).longValue();
        Announcement announcement = announcementService.createFromRequest(
                (String) body.get("title"),
                (String) body.get("content"),
                programmeId,
                institutionId.longValue()
        );
        // Let the programme's learners at this institution know straight away
        List<Long> recipients = userRepository.findBySelectedProgramme_IdAndRole(programmeId, User.Role.USER).stream()
                .filter(u -> u.getInstitution() != null && institutionId.equals(u.getInstitution().getId()))
                .map(User::getId)
                .toList();
        notificationService.notifyAll(recipients, Notification.Type.ANNOUNCEMENT,
                "Announcement: " + announcement.getTitle(), announcement.getContent());
        return ResponseEntity.status(HttpStatus.CREATED).body(announcement);
    }


    @GetMapping("/getByInstitutionAndProgramme")
    public ResponseEntity<List<Announcement>> getByInstitutionAndProgramme(
            @RequestParam int institutionId,
            @RequestParam int programmeId) {
        List<Announcement> announcements = announcementService.getByInstitutionAndProgramme(institutionId, programmeId);
        return ResponseEntity.ok(announcements);
    }
    @DeleteMapping("/delete/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','INSTRUCTOR','INSTITUTION')")
    public ResponseEntity<Void> delete(@PathVariable int id) {
        announcementService.delete(id);
        return ResponseEntity.noContent().build();
    }
}