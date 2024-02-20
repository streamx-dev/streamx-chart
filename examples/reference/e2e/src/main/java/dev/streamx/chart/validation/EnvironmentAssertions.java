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
import com.fasterxml.jackson.databind.ObjectMapper;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import java.util.concurrent.TimeUnit;
import java.util.function.Predicate;
import org.awaitility.Awaitility;

public class EnvironmentAssertions {

  public static void assertPageWithContent(RequestSpecification request, String expectedContent) {
    Response response = getResponse(request);

    response.then()
        .assertThat()
        .body(containsString(expectedContent));
  }

  public static void assertJsonSchema(RequestSpecification request, String expectedSchema)
      throws JsonProcessingException {
    Response response = getResponse(request);

    String schema = response.then()
        .extract().body().asString();

    assertNotNull(schema);
    ObjectMapper mapper = new ObjectMapper();
    assertEquals(mapper.readTree(expectedSchema), mapper.readTree(schema));
  }

  private static Response getResponse(RequestSpecification request) {
    return Awaitility.with()
        .pollDelay(0, TimeUnit.SECONDS)
        .pollInterval(1, TimeUnit.SECONDS)
        .atMost(60, TimeUnit.SECONDS)
        .until(request::get, isSuccess());
  }

  private static Predicate<Response> isSuccess() {
    return resp -> resp.statusCode() == 200;
  }

}

