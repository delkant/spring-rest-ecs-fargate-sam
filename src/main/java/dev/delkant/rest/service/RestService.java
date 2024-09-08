package dev.delkant.rest.service;

import dev.delkant.rest.model.Person;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

/**
 * @author rdelcanto
 */
@Service
@Slf4j
public class RestService {

    RestTemplate restTemplate;
    Environment environment;


    public RestService(RestTemplate restTemplate, Environment environment) {
        this.restTemplate = restTemplate;
        this.environment = environment;
    }


    public Person getPerson(String personId) {
        log.info("Person requested with id: {}", personId);
        return Person.builder().id(personId).firstName("Joe").lastName("Doe").build();
    }
}
