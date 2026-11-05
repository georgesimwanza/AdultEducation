package com.project.adult.Controller;

import com.project.adult.DTO.LearningDtos.*;
import com.project.adult.Service.CurrentUserService;
import com.project.adult.Service.MessageService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** Direct messaging between learners and instructors. */
@RestController
@RequestMapping("/api/messages")
public class MessageController {

    private final MessageService messageService;
    private final CurrentUserService currentUser;

    public MessageController(MessageService messageService, CurrentUserService currentUser) {
        this.messageService = messageService;
        this.currentUser = currentUser;
    }

    @GetMapping("/contacts")
    public List<ContactDto> contacts() {
        return messageService.contacts(currentUser.require());
    }

    @GetMapping("/conversations")
    public List<ConversationDto> conversations() {
        return messageService.conversations(currentUser.require());
    }

    @GetMapping("/with/{userId}")
    public List<MessageDto> thread(@PathVariable Long userId) {
        return messageService.thread(currentUser.require(), userId);
    }

    @PostMapping
    public MessageDto send(@RequestBody SendMessageRequest request) {
        return messageService.send(currentUser.require(), request);
    }

    @GetMapping("/unread-count")
    public Map<String, Long> unread() {
        return Map.of("count", messageService.unreadCount(currentUser.require()));
    }
}
