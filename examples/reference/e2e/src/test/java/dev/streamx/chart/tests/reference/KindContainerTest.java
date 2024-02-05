package dev.streamx.chart.tests.reference;

import static com.dajudge.kindcontainer.DeploymentAvailableWaitStrategy.deploymentIsAvailable;

import com.dajudge.kindcontainer.KindContainer;
import com.dajudge.kindcontainer.KindContainerVersion;
import com.dajudge.kindcontainer.KubernetesContainer;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.output.Slf4jLogConsumer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.MountableFile;

@Testcontainers
public class KindContainerTest {

  Logger log = LoggerFactory.getLogger("KindContainerTest");

  @Container
  private final KindContainer<?> KUBE = new KindContainer<>(KindContainerVersion.VERSION_1_28_0)
      .withExposedPorts(80, 443)
      .withLogConsumer(new Slf4jLogConsumer(log));

  @Test
  public void verify_node_is_present() {
    System.out.println(KUBE.getKubeconfig());
    installIngressController(KUBE);

    Integer httpPort = KUBE.getMappedPort(80);
    System.out.println("http://streamx.127.0.0.1.nip.io:" + httpPort + "/");
    installPulsar(KUBE);
    installStreamX(KUBE);
    System.out.println("test");
  }


  private void installIngressController(final KubernetesContainer<?> container) {
    container.withKubectl(kubectl -> {
      kubectl.label.with("ingress-ready", "true").run("node", "kind");
      kubectl.apply.from(
              "https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml")
          .run();
    }).waitingFor(deploymentIsAvailable("ingress-nginx", "ingress-nginx-controller"));
  }

  private void installPulsar(KindContainer<?> container) {
    container.withKubectl(kubectl -> {
      kubectl.apply.fileFromClasspath("pulsar.yaml").run();
    }).waitingFor(deploymentIsAvailable("pulsar", "pulsar"));
  }

  private void installStreamX(KindContainer<?> container) {
    String token = System.getenv("STREAMX_GAR_TOKEN");
    container.withKubectl(kubectl -> {
      kubectl.create.namespace.run("streamx");
      kubectl.create.secret.dockerRegistry
          .namespace("streamx")
          .dockerServer("europe-west1-docker.pkg.dev")
          .dockerUsername("oauth2accesstoken")
          .dockerPassword(token)
          .run("streamx-gar-json-key");
    });
    container.withHelm3(helm -> {
      helm.copyFileToContainer(MountableFile.forHostPath("../../../chart"), "/tmp/streamx");
      helm.install
          .namespace("streamx")
          .createNamespace(true)
          .set("imagePullSecrets[0].name", "streamx-gar-json-key")
          .set("rest_ingestion.enabled", "false")
          .run("streamx", "/tmp/streamx");
    });
    container.withHelm3(helm -> {
      helm.copyFileToContainer(MountableFile.forHostPath("../../../chart"), "/tmp/streamx");
      helm.install
          .namespace("streamx")
          .set("imagePullSecrets[0].name", "streamx-gar-json-key")
          .set("rest_ingestion.enabled", "false")
          .run("streamx", "/tmp/streamx");
    }).waitingFor(deploymentIsAvailable("streamx", "streamx-rest-ingestion"));
  }
}
