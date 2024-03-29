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

import static dev.streamx.chart.validation.EnvironmentAssertions.assertPageNotExists;
import static dev.streamx.chart.validation.EnvironmentAssertions.assertPageWithContent;

import com.fasterxml.jackson.core.JsonProcessingException;
import dev.streamx.clients.ingestion.exceptions.StreamxClientException;
import java.util.UUID;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

@ExtendWith(StreamXEnvironmentExtension.class)
@Tag("reference")
public class ReferencePublicationTest {

  static final String REFERENCE_PAGE_CONTENT = "<h1>Unit tests for reference StreamX flow</h1>";

  private static final String STRICT_SCHEMA = """
    {
       "pages": {
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
     }
     """;

  @Test
  void restIngestionShouldHavePagesSchemaConfigured(StreamXEnvironment environment)
      throws JsonProcessingException {
    EnvironmentAssertions.assertPagesJsonSchema(environment.newIngestionSchemaRequest());
  }

  @Test
  @Disabled("Enable after fixing DXP-695")
  void restIngestionShouldHaveStrictValue(StreamXEnvironment environment)
      throws JsonProcessingException {
    EnvironmentAssertions.assertStrictJsonSchema(environment.newIngestionSchemaRequest(), STRICT_SCHEMA);
  }

  @Test
  void publishedPageShouldBeAvailableOnWebDeliveryService(StreamXEnvironment environment)
      throws StreamxClientException {
    String key = "test-" + UUID.randomUUID() + ".html";

    Long eventTime = environment.publishPage(key, REFERENCE_PAGE_CONTENT);

    Assertions.assertTrue(eventTime > 0L);
    assertPageWithContent(environment.newDeliveryPageRequest(key), REFERENCE_PAGE_CONTENT);

    environment.unpublishPage(key);
    assertPageNotExists(environment.newDeliveryPageRequest(key));
  }

  @Test
  void makeSureAuthEndpointIsNotExposedPublicly(StreamXEnvironment environment) {
    environment.newIngestionRequest("/auth/token?upn=test")
        .post()
        .then()
        .assertThat()
        .statusCode(404);
  }

}
