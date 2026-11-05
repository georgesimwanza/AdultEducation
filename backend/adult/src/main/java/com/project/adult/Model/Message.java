package com.project.adult.Model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** A direct message between two users (learner and instructor/admin). */
@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Table(name = "messages",
        indexes = {
                @Index(name = "idx_message_recipient", columnList = "recipient_id, read_at"),
                @Index(name = "idx_message_pair", columnList = "sender_id, recipient_id, sent_at")
        })
public class Message {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sender_id")
    private User sender;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipient_id")
    private User recipient;

    @Column(nullable = false, length = 4000)
    private String body;

    @Column(name = "sent_at", nullable = false)
    private LocalDateTime sentAt = LocalDateTime.now();

    @Column(name = "read_at")
    private LocalDateTime readAt;
}
