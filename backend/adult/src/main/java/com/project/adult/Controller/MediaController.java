package com.project.adult.Controller;

import com.project.adult.Service.MediaMirrorService;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.MediaTypeFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.nio.file.Path;

/**
 * Content mirror: serves lesson files (PDFs, videos, images) from this
 * server so devices without internet, e.g. phones on the school network,
 * can still download them. See MediaMirrorService for how copies are kept.
 */
@RestController
@RequestMapping("/api/media")
public class MediaController {

    private final MediaMirrorService mirror;

    public MediaController(MediaMirrorService mirror) {
        this.mirror = mirror;
    }

    @GetMapping("/file")
    public ResponseEntity<Resource> file(@RequestParam String url) {
        if (!mirror.isAllowed(url)) {
            return ResponseEntity.badRequest().build();
        }
        Path cached;
        try {
            cached = mirror.fetch(url);
        } catch (IOException e) {
            // CDN unreachable (or missing the file) and no copy kept yet.
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY).build();
        }
        MediaType type = MediaTypeFactory.getMediaType(cached.getFileName().toString())
                .orElse(MediaType.APPLICATION_OCTET_STREAM);
        // A Resource body lets Spring answer Range requests, so videos can seek.
        return ResponseEntity.ok().contentType(type).body(new FileSystemResource(cached));
    }
}
