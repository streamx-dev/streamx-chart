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

import static dev.streamx.chart.validation.EnvironmentAssertions.assertJsonSchema;
import static dev.streamx.chart.validation.EnvironmentAssertions.assertPageNotExists;
import static dev.streamx.chart.validation.EnvironmentAssertions.assertPageWithContent;

import dev.streamx.clients.ingestion.exceptions.StreamxClientException;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

import com.fasterxml.jackson.core.JsonProcessingException;

@Tag("multi-tenant")
public class MultiTenantPublicationTest {

  private final StreamXEnvironment tenant1 = new StreamXEnvironment("http://tenant-1-api.127.0.0.1.nip.io", "http://tenant-1.127.0.0.1.nip.io", "STREAMX_INGESTION_REST_AUTH_TOKEN_TENANT_1");

  private final StreamXEnvironment tenant2 = new StreamXEnvironment("http://tenant-2-api.127.0.0.1.nip.io", "http://tenant-2.127.0.0.1.nip.io", "STREAMX_INGESTION_REST_AUTH_TOKEN_TENANT_2");

  @Test
  // FixMe order should not matter after schema autoupdate implemented in StreamX
  @Order(1)
  void restIngestionShouldHavePagesSchemaConfigured()
      throws JsonProcessingException {
    assertJsonSchema(tenant1.newIngestionSchemaRequest());
    assertJsonSchema(tenant2.newIngestionSchemaRequest());
  }

  @Test
  @Order(2)
  @DisplayName("Check page published on first tenant is not visible on second tenant")
  public void checkTenantsPublicationSeparation() throws StreamxClientException {
    String tenant1Key = "test-" + UUID.randomUUID() + ".html";

    // publish page on tenant 1
    tenant1.publishPage(tenant1Key, "<html><body><h1>Hello tenant 1!</h1></body></html>");
    assertPageWithContent(tenant1.newDeliveryPageRequest(tenant1Key), "Hello tenant 1!");
    assertPageNotExists(tenant2.newDeliveryPageRequest(tenant1Key));

    // publish page on tenant 2
    String tenant2Key = "test-" + UUID.randomUUID() + ".html";
    tenant2.publishPage(tenant2Key, "<html><body><h1>Hello tenant 2!</h1></body></html>");
    assertPageWithContent(tenant2.newDeliveryPageRequest(tenant2Key), "Hello tenant 2!");

    // check tenant 1 resource hasn't changed
    assertPageWithContent(tenant1.newDeliveryPageRequest(tenant1Key), "Hello tenant 1!");
  }

}
