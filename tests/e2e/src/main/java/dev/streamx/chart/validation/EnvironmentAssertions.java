/*
 * Copyright 2024 Dynamic Solutions Sp. z o.o. sp.k.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package dev.streamx.chart.validation;

import static org.hamcrest.core.StringContains.containsString;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import java.util.concurrent.TimeUnit;
import java.util.function.Predicate;
import org.awaitility.Awaitility;

public class EnvironmentAssertions {

  private static final String PAGES_SCHEMA = """
     {
       "type":"record",
       "name":"Page",
       "namespace":"dev.streamx.reference.relay.model",
       "fields":[
         {
           "name":"content",
           "type":[
             "null",
             "bytes"
           ],
           "default":null
         }
       ]
     }
     """;

  public static void assertPageWithContent(RequestSpecification request, String expectedContent) {
    Response response = getResponse(request, isOk());

    response.then()
        .assertThat()
        .body(containsString(expectedContent));
  }

  public static void assertPageNotExists(RequestSpecification request) {
    getResponse(request, isNotFound());
  }

  public static void assertUnauthenticated(RequestSpecification request) {
    getResponse(request, isNotAuth());
  }

  public static void assertPagesJsonSchema(RequestSpecification request) throws JsonProcessingException {
    assertJsonSchema(request, "pages", PAGES_SCHEMA);
  }

  public static void assertJsonSchema(RequestSpecification request, String schemaName, String expectedSchema)
      throws JsonProcessingException {
    Response response = getResponse(request, isOk());

    String schema = response.then()
        .extract().body().asString();

    assertNotNull(schema);
    ObjectMapper mapper = new ObjectMapper();
    JsonNode schemaResponse = mapper.readTree(schema).get(schemaName);
    assertNotNull(schemaResponse);
    assertEquals(mapper.readTree(expectedSchema), schemaResponse);
  }

  public static void assertStrictJsonSchema(RequestSpecification request, String expectedSchema)
      throws JsonProcessingException {
    Response response = getResponse(request, isOk());

    String schema = response.then()
        .extract().body().asString();

    assertNotNull(schema);
    ObjectMapper mapper = new ObjectMapper();
    assertEquals(mapper.readTree(expectedSchema), mapper.readTree(schema));
  }

  private static Response getResponse(RequestSpecification request, Predicate<Response> expected) {
    return Awaitility.with()
        .pollDelay(0, TimeUnit.SECONDS)
        .pollInterval(1, TimeUnit.SECONDS)
        .atMost(60, TimeUnit.SECONDS)
        .until(request::get, expected);
  }

  private static Predicate<Response> isOk() {
    return resp -> resp.statusCode() == 200;
  }

  private static Predicate<Response> isNotFound() {
    return resp -> resp.statusCode() == 404;
  }

  private static Predicate<Response> isNotAuth() {
    return resp -> resp.statusCode() == 401;
  }

}

