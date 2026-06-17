package com.example.${{ values.serviceName | replace('-', '') }};

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.lang.management.ManagementFactory;
import java.util.Map;

@RestController
public class HealthController {

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of(
            "status", "healthy",
            "service", "${{ values.serviceName }}"
        );
    }

    @GetMapping("/ready")
    public Map<String, Object> ready() {
        long uptimeMs = ManagementFactory.getRuntimeMXBean().getUptime();
        return Map.of(
            "status", "ready",
            "uptime_seconds", uptimeMs / 1000
        );
    }

    @GetMapping("/metrics")
    public Map<String, Object> metrics() {
        long uptimeMs = ManagementFactory.getRuntimeMXBean().getUptime();
        return Map.of(
            "service", "${{ values.serviceName }}",
            "uptime_seconds", uptimeMs / 1000
        );
    }
}
