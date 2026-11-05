package com.project.adult.Controller;

import com.project.adult.Model.Notification;
import com.project.adult.Service.CurrentUserService;
import com.project.adult.Service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** The signed-in user's notifications (deadlines, grades, announcements, messages). */
@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService notificationService;
    private final CurrentUserService currentUser;

    public NotificationController(NotificationService notificationService, CurrentUserService currentUser) {
        this.notificationService = notificationService;
        this.currentUser = currentUser;
    }

    @GetMapping
    public List<Notification> list(@RequestParam(defaultValue = "50") int limit) {
        return notificationService.list(currentUser.require().getId(), limit);
    }

    @GetMapping("/unread-count")
    public Map<String, Long> unread() {
        return Map.of("count", notificationService.unreadCount(currentUser.require().getId()));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<Void> markRead(@PathVariable Long id) {
        notificationService.markRead(currentUser.require().getId(), id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/read-all")
    public ResponseEntity<Void> markAllRead() {
        notificationService.markAllRead(currentUser.require().getId());
        return ResponseEntity.noContent().build();
    }
}
