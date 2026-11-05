package com.project.adult.Service;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Model.ActivityEvent;
import com.project.adult.Model.Message;
import com.project.adult.Model.Notification;
import com.project.adult.Model.User;
import com.project.adult.Repository.MessageRepository;
import com.project.adult.Repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Direct messages within an institution. Learners can message staff
 * (instructors and admins); staff can message anyone in their institution.
 */
@Service
public class MessageService {

    private static final List<User.Role> STAFF_ROLES =
            List.of(User.Role.INSTRUCTOR, User.Role.ADMIN, User.Role.INSTITUTION);
    private static final List<User.Role> ALL_ROLES = List.of(User.Role.values());

    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final ActivityService activityService;

    public MessageService(MessageRepository messageRepository,
                          UserRepository userRepository,
                          NotificationService notificationService,
                          ActivityService activityService) {
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
        this.activityService = activityService;
    }

    public List<ContactDto> contacts(User me) {
        Long institutionId = CurrentUserService.institutionId(me);
        if (institutionId == null) return List.of();
        List<User.Role> roles = CurrentUserService.isStaff(me) ? ALL_ROLES : STAFF_ROLES;
        return userRepository.findByInstitution_IdAndRoleIn(institutionId, roles).stream()
                .filter(u -> !u.getId().equals(me.getId()) && !Boolean.FALSE.equals(u.getIsActive()))
                .sorted(Comparator.comparing(User::getFirstName))
                .map(u -> new ContactDto(u.getId(), ProfileService.fullName(u), u.getRole().name()))
                .toList();
    }

    /** One row per person the user has messaged with, newest first. */
    public List<ConversationDto> conversations(User me) {
        Map<Long, ConversationDto> byUser = new LinkedHashMap<>();
        Map<Long, Long> unread = new HashMap<>();
        for (Message m : messageRepository.findAllInvolving(me.getId())) {
            boolean mine = m.getSender().getId().equals(me.getId());
            User other = mine ? m.getRecipient() : m.getSender();
            if (!mine && m.getReadAt() == null) unread.merge(other.getId(), 1L, Long::sum);
            byUser.putIfAbsent(other.getId(), new ConversationDto(other.getId(), ProfileService.fullName(other),
                    other.getRole().name(), m.getBody(), m.getSentAt(), 0));
        }
        return byUser.values().stream()
                .map(c -> new ConversationDto(c.userId(), c.name(), c.role(), c.lastMessage(), c.lastAt(),
                        unread.getOrDefault(c.userId(), 0L)))
                .toList();
    }

    /** Full thread with another user; opening it marks their messages as read. */
    @Transactional
    public List<MessageDto> thread(User me, Long otherId) {
        messageRepository.markRead(me.getId(), otherId, LocalDateTime.now());
        return messageRepository.findConversation(me.getId(), otherId).stream()
                .map(m -> toDto(m, me))
                .toList();
    }

    @Transactional
    public MessageDto send(User me, SendMessageRequest req) {
        if (req.body() == null || req.body().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Message can't be empty");
        }
        if (req.body().length() > 4000) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Message is too long (4000 characters max)");
        }
        User recipient = userRepository.findById(req.recipientId() != null ? req.recipientId() : -1L)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Recipient not found"));
        boolean allowed = contacts(me).stream().anyMatch(c -> c.id().equals(recipient.getId()))
                // A staff member who wrote first can always be answered
                || !messageRepository.findConversation(me.getId(), recipient.getId()).isEmpty();
        if (!allowed) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You can't message this person");
        }
        Message m = new Message();
        m.setSender(me);
        m.setRecipient(recipient);
        m.setBody(req.body().trim());
        m = messageRepository.save(m);
        notificationService.notify(recipient.getId(), Notification.Type.MESSAGE,
                "New message from " + ProfileService.fullName(me),
                m.getBody().length() > 120 ? m.getBody().substring(0, 120) + "…" : m.getBody());
        activityService.record(me.getId(), ActivityEvent.Type.SEND_MESSAGE, null, null);
        return toDto(m, me);
    }

    public long unreadCount(User me) {
        return messageRepository.countByRecipient_IdAndReadAtIsNull(me.getId());
    }

    private static MessageDto toDto(Message m, User me) {
        return new MessageDto(m.getId(), m.getSender().getId(), ProfileService.fullName(m.getSender()),
                m.getRecipient().getId(), ProfileService.fullName(m.getRecipient()), m.getBody(),
                m.getSentAt(), m.getReadAt(), m.getSender().getId().equals(me.getId()));
    }
}
