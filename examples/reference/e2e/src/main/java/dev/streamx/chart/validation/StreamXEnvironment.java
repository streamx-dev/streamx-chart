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

import static io.restassured.RestAssured.given;
import static org.junit.jupiter.api.Assertions.assertNotNull;

import dev.streamx.chart.validation.model.Page;
import dev.streamx.clients.ingestion.StreamxClient;
import dev.streamx.clients.ingestion.exceptions.StreamxClientException;
import dev.streamx.clients.ingestion.publisher.Publisher;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import org.jboss.logging.Logger;

public class StreamXEnvironment {

  private static final Logger LOG = Logger.getLogger(StreamXEnvironment.class);
  private static final String PAGES_INBOX_CHANNEL = "pages";
  private static final String PUBLICATIONS_API_BASE_PATH = "/publications/v1";
  public static final String REST_INGESTION_HOST = "http://streamx-api.127.0.0.1.nip.io";


  public Long publishPage(String key, String content) throws StreamxClientException {
    LOG.infof("Publishing page %s with content '%s'", key, content);
    try (StreamxClient client = StreamxClient.create(REST_INGESTION_HOST, getAuthToken())) {
      Publisher<Page> pagePublisher = client.newPublisher(PAGES_INBOX_CHANNEL, Page.class);
      Long eventTime = pagePublisher.publish(key,
          new Page(ByteBuffer.wrap(content.getBytes(StandardCharsets.UTF_8))));
      assertNotNull(eventTime);
      return eventTime;
    }
  }
  public RequestSpecification newIngestionSchemaRequest() {
    return given()
        .baseUri(REST_INGESTION_HOST + PUBLICATIONS_API_BASE_PATH)
        .basePath("/schema")
        .header("Authorization", "Bearer " + getAuthToken())
        .contentType(ContentType.JSON);
  }

  public RequestSpecification newDeliveryPageRequest(String pagePath) {
    return given()
        .baseUri("http://streamx.127.0.0.1.nip.io")
        .basePath(pagePath)
        .contentType(ContentType.HTML);
  }

  protected String getAuthToken() {
    return System.getenv("STREAMX_INGESTION_REST_AUTH_TOKEN");
  }

}
