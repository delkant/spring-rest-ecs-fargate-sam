package dev.delkant.rest.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import dev.delkant.rest.model.Person;
import dev.delkant.rest.service.RestService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;

import java.io.IOException;
import java.net.InetAddress;
import java.net.URI;
import java.net.UnknownHostException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

/**
 * @author rdelcanto
 */
@org.springframework.web.bind.annotation.RestController
@RequestMapping("/api")
@Slf4j
public class RestController {


    final RestService tssService;

    final Environment environment;
    @Value("${server.port}")
    private String port;
    @Value("${ecs.container.metadata.uri}")
    private String metadataUri;

    RestController(Environment environment, RestService tssService) {
        this.environment = environment;
        this.tssService = tssService;
        log.info("REST API started on port {}", port);
    }


    @GetMapping("/person/{id}")
    public ResponseEntity<Person> getPerson(@PathVariable("id") String domainId) {
        Person returnValue = tssService.getPerson(domainId);
        return ResponseEntity.status(HttpStatus.OK).body(returnValue);
    }


    @GetMapping("/ip")
    public String getIp() {
        String returnValue;

        try {
            InetAddress ipAddr = InetAddress.getLocalHost();
            returnValue = ipAddr.getHostAddress();
        } catch (UnknownHostException ex) {
            returnValue = ex.getLocalizedMessage();
        }

        return returnValue;
    }

    @GetMapping("/container-ip")
    public String getContainerPrivateIp() {
        String privateIp;
        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(metadataUri))
                .build();

        HttpResponse<String> response;
        try {
            response = client.send(request, HttpResponse.BodyHandlers.ofString());
            JsonNode json = new ObjectMapper().readTree(response.body());

            privateIp = json.get("Networks")
                    .get(0)
                    .get("IPv4Addresses")
                    .get(0)
                    .textValue();

        } catch (IOException | InterruptedException e) {
            privateIp = e.getLocalizedMessage();
            log.error(e.getLocalizedMessage());
        }
        return privateIp;
    }
}