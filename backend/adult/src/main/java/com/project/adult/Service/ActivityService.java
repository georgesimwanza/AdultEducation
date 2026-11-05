package com.project.adult.Service;

import com.project.adult.Model.ActivityEvent;
import com.project.adult.Repository.ActivityEventRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Records learner activity for participation monitoring. Logging must never
 * break the action being logged, so failures are swallowed.
 */
@Service
public class ActivityService {

    private final ActivityEventRepository repository;

    public ActivityService(ActivityEventRepository repository) {
        this.repository = repository;
    }

    public void record(Long userId, ActivityEvent.Type type, Long courseId, String description) {
        if (userId == null) return;
        try {
            repository.save(new ActivityEvent(userId, type, courseId, description));
        } catch (Exception e) {
            System.err.println("Could not record activity: " + e.getMessage());
        }
    }

    public List<ActivityEvent> recent(Long userId, int limit) {
        return repository.findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(0, limit));
    }
}
