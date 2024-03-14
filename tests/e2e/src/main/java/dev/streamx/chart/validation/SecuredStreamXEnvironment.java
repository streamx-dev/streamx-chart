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

import dev.streamx.clients.ingestion.StreamxClient;
import dev.streamx.clients.ingestion.exceptions.StreamxClientException;
import io.restassured.specification.RequestSpecification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SecuredStreamXEnvironment extends StreamXEnvironment {

  private static final Logger LOG = LoggerFactory.getLogger(SecuredStreamXEnvironment.class);
  private final String authTokenEnv;

  public SecuredStreamXEnvironment(String restIngestionHost, String webDeliveryHost,
      String authTokenEnv) {
    super(restIngestionHost, webDeliveryHost);
    this.authTokenEnv = authTokenEnv;
  }

  @Override
  protected StreamxClient getClient() throws StreamxClientException {
    return StreamxClient.create(restIngestionHost, getAuthToken());
  }

  @Override
  public RequestSpecification newIngestionSchemaRequest() {
    RequestSpecification requestSpecification = super.newIngestionSchemaRequest();
    requestSpecification.header("Authorization", "Bearer " + getAuthToken());
    return requestSpecification;
  }

  private String getAuthToken() {
    String authToken = System.getenv(authTokenEnv);
    if (authToken != null) {
      LOG.info("Token {} last 20 chars: '...{}'", authTokenEnv, authToken.substring(authToken.length() - 20));
    } else {
      LOG.warn("Token {} is null!", authTokenEnv);
    }

    return authToken;
  }


}
