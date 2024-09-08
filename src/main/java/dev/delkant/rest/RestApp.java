package dev.delkant.rest;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.core.env.Environment;
import org.springframework.web.client.RestTemplate;

/**
 *
 * @author rdelcanto
 */
@SpringBootApplication
public class RestApp {

    final Environment environment;

    RestApp(Environment environment) {
        this.environment = environment;
    }

    public static void main(String[] args) {
        SpringApplication.run(RestApp.class, args);
    }


    @Bean
    public SpringApplicationContext springApplicationContext() {
        return new SpringApplicationContext();
    }

    @Bean
    public RestTemplate getRestTemplate() {
        return new RestTemplate();
    }

}