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

import io.restassured.RestAssured;
import io.restassured.filter.log.RequestLoggingFilter;
import io.restassured.filter.log.ResponseLoggingFilter;
import org.junit.jupiter.api.extension.BeforeAllCallback;
import org.junit.jupiter.api.extension.ExtensionContext;
import org.junit.jupiter.api.extension.ParameterContext;
import org.junit.jupiter.api.extension.ParameterResolutionException;
import org.junit.jupiter.api.extension.ParameterResolver;

public class StreamXEnvironmentExtension implements BeforeAllCallback, ParameterResolver {

  @Override
  public void beforeAll(ExtensionContext extensionContext) {
    RestAssured.filters(new RequestLoggingFilter(), new ResponseLoggingFilter());
  }

  @Override
  public boolean supportsParameter(ParameterContext parameterContext,
      ExtensionContext extensionContext) throws ParameterResolutionException {
    Class<?> type = parameterContext.getParameter().getType();
    return type.equals(StreamXEnvironment.class) || type.equals(SecuredStreamXEnvironment.class);
  }

  @Override
  public Object resolveParameter(ParameterContext parameterContext,
      ExtensionContext extensionContext) throws ParameterResolutionException {
    Class<?> type = parameterContext.getParameter().getType();
    if (type.equals(StreamXEnvironment.class)) {
      return StreamXEnvironment.newLocalEnvironment("reference");
    } else {
      return new SecuredStreamXEnvironment(
          "http://secured-api.127.0.0.1.nip.io", "http://secured.127.0.0.1.nip.io",
          "STREAMX_INGESTION_REST_AUTH_TOKEN");
    }
  }

}
