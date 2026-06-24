package com.project.adult.Controller;

import com.project.adult.DTO.ContentDTO;
import com.project.adult.Model.Content;
import com.project.adult.Service.ContentService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/Content")
public class ContentController {

    private final ContentService contentService;

    public ContentController(ContentService contentService) {
        this.contentService = contentService;
    }

    @PostMapping("/addContent")
    public ContentDTO addContent(@RequestBody ContentDTO contentDTO){
      return contentService.addContent(contentDTO);
    }

    @GetMapping("/course/{courseId}")
    public List<ContentDTO> getContentByCourseId(@PathVariable Long courseId) {
        return contentService.getContentById(courseId);
    }
    @GetMapping("getAllContent")
    public List<Content> getAllContent(){
        return this.contentService.getAllContent();
    }
}