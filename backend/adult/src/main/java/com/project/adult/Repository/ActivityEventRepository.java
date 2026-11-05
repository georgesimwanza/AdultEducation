package com.project.adult.Repository;

import com.project.adult.Model.ActivityEvent;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

public interface ActivityEventRepository extends JpaRepository<ActivityEvent, Long> {

    List<ActivityEvent> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable page);

    long countByUserIdAndCreatedAtAfter(Long userId, LocalDateTime since);

    /** Rows of [userId, eventCount, lastActivity] for the given users since a date. */
    @Query("SELECT e.userId, COUNT(e), MAX(e.createdAt) FROM ActivityEvent e " +
            "WHERE e.userId IN :userIds AND e.createdAt >= :since GROUP BY e.userId")
    List<Object[]> summariseByUser(@Param("userIds") Collection<Long> userIds, @Param("since") LocalDateTime since);
}
