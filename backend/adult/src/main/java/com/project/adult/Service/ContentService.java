package com.project.adult.Service;


import com.project.adult.DTO.ContentDTO;
import com.project.adult.Model.Content;
import com.project.adult.Repository.ContentRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class ContentService {
    private final ContentRepository contentRepository;


    public ContentService(ContentRepository contentRepository) {
        this.contentRepository = contentRepository;
    }

    public ContentDTO addContent(@RequestBody ContentDTO contentDTO) {
        Content content = new Content();
        content.setTitle(contentDTO.getTitle());
        content.setType(contentDTO.getType());
        content.setId(contentDTO.getId());
        content.setFileUrl(contentDTO.getFile_Url());

        Content savedContent = contentRepository.save(content);

        ContentDTO responseDTO = new ContentDTO();
        responseDTO.setId(savedContent.getId());
        responseDTO.setTitle(savedContent.getTitle());
        responseDTO.setType(savedContent.getType());
        responseDTO.setFile_Url(savedContent.getFileUrl());

        return responseDTO;
    }
    public List<ContentDTO> getContentById(Long id) {
        return contentRepository.findContentbySubjectId(id)
                .stream()
                .map(c -> ContentDTO.builder()
                        .id(c.getId())
                        .type(c.getType())
                        .title(c.getTitle())
                        .file_Url(c.getFileUrl())
                        .build())
                .collect(Collectors.toList());
    }
}
