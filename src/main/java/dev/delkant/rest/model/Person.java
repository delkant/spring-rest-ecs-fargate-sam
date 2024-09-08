package dev.delkant.rest.model;

import lombok.Builder;

@Builder
public record Person(String id, String firstName, String lastName) {
}
