package com.project.adult.Service;

import com.project.adult.Model.Content;
import com.project.adult.Repository.ContentRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Duration;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Keeps a copy of every lesson file (PDFs, videos, images) on this server,
 * so devices without internet can download them from here.
 *
 * Copies are fetched in the background soon after start-up and every half
 * hour (for new uploads), several at a time, so a phone's request is
 * normally served straight from disk. Only URLs under the CDN prefix are
 * fetched, so the mirror can't be used to reach arbitrary sites.
 */
@Service
public class MediaMirrorService {

    private static final Logger log = LoggerFactory.getLogger(MediaMirrorService.class);

    /** Files fetched from the CDN at the same time. */
    private static final int PARALLEL = 3;

    private final ContentRepository contentRepository;
    private final String allowedPrefix;
    private final Path cacheDir;
    private final HttpClient http = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(15))
            .build();
    private final ExecutorService pool = Executors.newFixedThreadPool(PARALLEL);
    /** One download per file, shared by everyone asking for it meanwhile. */
    private final Map<String, CompletableFuture<Path>> inFlight = new ConcurrentHashMap<>();

    public MediaMirrorService(
            ContentRepository contentRepository,
            @Value("${media.cdn-prefix}") String allowedPrefix,
            @Value("${media.cache-dir:media-cache}") String cacheDir) {
        this.contentRepository = contentRepository;
        this.allowedPrefix = allowedPrefix;
        this.cacheDir = Path.of(cacheDir).toAbsolutePath();
    }

    public boolean isAllowed(String url) {
        return url != null && url.startsWith(allowedPrefix) && !url.contains("..");
    }

    /** Where the copy of [url] is (or will be) kept. */
    public Path pathFor(String url) {
        return cacheDir.resolve(sha256(url) + extension(url));
    }

    /**
     * The local copy of [url], fetching it first if needed.
     * Throws IOException if the CDN can't be reached and there is no copy.
     */
    public Path fetch(String url) throws IOException {
        Path cached = pathFor(url);
        if (Files.exists(cached)) return cached;
        CompletableFuture<Path> job = inFlight.computeIfAbsent(url,
                u -> CompletableFuture.supplyAsync(() -> download(u), pool)
                        .whenComplete((p, e) -> inFlight.remove(u)));
        try {
            return job.join();
        } catch (Exception e) {
            Throwable cause = e.getCause() != null ? e.getCause() : e;
            if (cause instanceof UncheckedIOException u) throw u.getCause();
            throw new IOException(cause);
        }
    }

    /** Fetches every lesson file not kept yet, a few at a time. */
    @Scheduled(initialDelay = 20_000, fixedDelay = 30 * 60_000)
    public void warmUp() {
        List<String> missing = contentRepository.findAll().stream()
                .map(Content::getFileUrl)
                .filter(this::isAllowed)
                .distinct()
                .filter(u -> !Files.exists(pathFor(u)))
                .toList();
        if (missing.isEmpty()) return;
        log.info("Content mirror: fetching {} lesson files", missing.size());
        // Not joined: the scheduler thread is shared with other jobs.
        CompletableFuture.allOf(missing.stream()
                .map(u -> CompletableFuture.runAsync(() -> {
                    try {
                        fetch(u);
                    } catch (IOException e) {
                        log.warn("Content mirror: could not fetch {} ({})", u, e.getMessage());
                    }
                }))
                .toArray(CompletableFuture[]::new))
                .thenRun(() -> log.info("Content mirror: done"));
    }

    private Path download(String url) {
        try {
            Files.createDirectories(cacheDir);
            Path cached = pathFor(url);
            // Download beside the final name, then move, so a dropped
            // connection never leaves a half file that looks complete.
            Path part = Files.createTempFile(cacheDir, "dl-", ".part");
            try {
                HttpResponse<Path> res = http.send(
                        HttpRequest.newBuilder(URI.create(url)).timeout(Duration.ofMinutes(30)).build(),
                        HttpResponse.BodyHandlers.ofFile(part));
                if (res.statusCode() != 200) {
                    throw new IOException("CDN answered " + res.statusCode());
                }
                Files.move(part, cached, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
                return cached;
            } finally {
                Files.deleteIfExists(part);
            }
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new UncheckedIOException(new IOException(e));
        }
    }

    private static String extension(String url) {
        String path = URI.create(url).getPath();
        int dot = path.lastIndexOf('.');
        String ext = dot < 0 ? "" : path.substring(dot).toLowerCase();
        return ext.matches("\\.[a-z0-9]{1,5}") ? ext : "";
    }

    private static String sha256(String s) {
        try {
            byte[] hash = MessageDigest.getInstance("SHA-256").digest(s.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
