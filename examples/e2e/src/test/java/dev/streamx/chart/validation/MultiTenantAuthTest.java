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

import static dev.streamx.chart.validation.EnvironmentAssertions.assertUnauthenticated;

import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;

@Tag("multi-tenant")
public class MultiTenantAuthTest {

  private final StreamXEnvironment invalidAuthTenant1 = new StreamXEnvironment(
      "http://tenant-1-api.127.0.0.1.nip.io", "http://tenant-1.127.0.0.1.nip.io",
      "STREAMX_INGESTION_REST_AUTH_TOKEN_TENANT_2");

  private final StreamXEnvironment invalidAuthTenant2 = new StreamXEnvironment(
      "http://tenant-2-api.127.0.0.1.nip.io", "http://tenant-2.127.0.0.1.nip.io",
      "STREAMX_INGESTION_REST_AUTH_TOKEN_TENANT_1");

  @Test
  void restIngestionShouldHavePagesSchemaConfigured() {
    assertUnauthenticated(invalidAuthTenant1.newIngestionSchemaRequest());
    assertUnauthenticated(invalidAuthTenant2.newIngestionSchemaRequest());
  }

}
