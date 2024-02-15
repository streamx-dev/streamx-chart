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
package dev.streamx.reference.it;

import static io.restassured.RestAssured.given;
import static org.hamcrest.core.StringContains.containsString;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import dev.streamx.clients.ingestion.StreamxClient;
import dev.streamx.clients.ingestion.exceptions.StreamxClientException;
import dev.streamx.clients.ingestion.publisher.Publisher;
import dev.streamx.it.services.suite.extension.Environment;
import dev.streamx.it.services.suite.extension.TestContainersEnvironment;
import dev.streamx.reference.relay.model.Page;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import org.apache.http.HttpHeaders;
import org.apache.pulsar.client.admin.PulsarAdmin;
import org.apache.pulsar.client.admin.PulsarAdminException;
import org.apache.pulsar.client.api.PulsarClientException;
import org.apache.pulsar.common.policies.data.TopicStats;
import org.jboss.logging.Logger;


public class KindEnvironment implements Environment {

  private static final Logger LOG = org.jboss.logging.Logger.getLogger(KindEnvironment.class);
  public static final String STREAMX_REST_URL = "http://streamx-api.127.0.0.1.nip.io";
  public static final String WEB_URL = "http://streamx.127.0.0.1.nip.io";
  public static final String PULSAR_ADMIN_URL = "http://localhost:65328";

  @Override
  public Long publishPage(String key, String content) throws StreamxClientException {
    try (StreamxClient client = StreamxClient.create(STREAMX_REST_URL, System.getenv("STREAMX_INGESTION_REST_AUTH_TOKEN"))) {
      Publisher<Page> pagePublisher = client.newPublisher("pages", Page.class);
      Long eventTime = pagePublisher.publish(key,
          new Page(ByteBuffer.wrap(content.getBytes(StandardCharsets.UTF_8))));
      assertNotNull(eventTime);
      return eventTime;
    }
  }

  @Override
  public boolean hasSchema(String schema) {
    try {
      String responseJson = given().baseUri(STREAMX_REST_URL + "/publications/v1")
          .header(HttpHeaders.AUTHORIZATION, "Bearer " + System.getenv("STREAMX_INGESTION_REST_AUTH_TOKEN"))
          .when().get("/schema")
          .then().statusCode(200)
          .extract().body().asString();
      assertNotNull(responseJson);
      ObjectMapper mapper = new ObjectMapper();
      assertEquals(mapper.readTree(schema), mapper.readTree(responseJson));
    } catch (JsonProcessingException e) {
      throw new IllegalStateException("Schema in invalid format", e);
    } catch (AssertionError err) {
      return false;
    }
    return true;
  }

  @Override
  public boolean hasPage(String key, String content) {
    try {
      given().baseUri(WEB_URL)
          .when().get(key)
          .then()
          .statusCode(200)
          .assertThat()
          .body(containsString(content));
    } catch (AssertionError err) {
      return false;
    }
    return true;
  }

  @Override
  public TopicStats getStoreTopicStats(String topic) {
    try {
      try (PulsarAdmin admin = PulsarAdmin.builder().serviceHttpUrl(PULSAR_ADMIN_URL)
          .build()) {
        return admin.topics().getStats(TestContainersEnvironment.getTopicName(
            "streamx/stores", topic));
      }
    } catch (PulsarAdminException | PulsarClientException e) {
      LOG.error(e.getMessage(), e);
      return null;
    }
  }

}
