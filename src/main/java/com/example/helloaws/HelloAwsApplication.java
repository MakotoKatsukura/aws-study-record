package com.example.helloaws;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class HelloAwsApplication {
    public static void main(String[] args) {
        SpringApplication.run(HelloAwsApplication.class, args);
    }

    @GetMapping("/")
    public String hello() {
        return "Hello, AWS! (Ansible)";
    }
}
