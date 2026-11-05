package com.project.adult.Repository;

import com.project.adult.Model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface MessageRepository extends JpaRepository<Message, Long> {

    @Query("SELECT m FROM Message m JOIN FETCH m.sender JOIN FETCH m.recipient " +
            "WHERE (m.sender.id = :a AND m.recipient.id = :b) OR (m.sender.id = :b AND m.recipient.id = :a) " +
            "ORDER BY m.sentAt")
    List<Message> findConversation(@Param("a") Long a, @Param("b") Long b);

    @Query("SELECT m FROM Message m JOIN FETCH m.sender JOIN FETCH m.recipient " +
            "WHERE m.sender.id = :userId OR m.recipient.id = :userId ORDER BY m.sentAt DESC")
    List<Message> findAllInvolving(@Param("userId") Long userId);

    long countByRecipient_IdAndReadAtIsNull(Long recipientId);

    @Modifying
    @Query("UPDATE Message m SET m.readAt = :now WHERE m.recipient.id = :me AND m.sender.id = :other AND m.readAt IS NULL")
    int markRead(@Param("me") Long me, @Param("other") Long other, @Param("now") LocalDateTime now);
}
