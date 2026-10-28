# Net-tools CI on Minikube

Jenkins builds and pushes versioned Rocky and Ubuntu agent images to Docker Hub,
then runs the build/test stages concurrently in temporary Kubernetes pods using
those images. RPM and DEB artifacts are archived by Jenkins from each agent
workspace.

## Prerequisites

- Minikube and `kubectl` installed.
- A Minikube cluster with enough resources for Jenkins and both builds. For
  example: `minikube start --cpus=4 --memory=8192`.
- The existing Jenkins PV host path available in Minikube at
  `/mnt/data/jenkins-home`. The supplied PV uses `hostPath`, which is suitable
  for a single-node local cluster, not a multi-node or production cluster.
  Create it in the Minikube node and make it writable by the Jenkins UID before
  deploying Jenkins:

  ```sh
  minikube ssh -- "sudo mkdir -p /mnt/data/jenkins-home && sudo chown 1000:1000 /mnt/data/jenkins-home"
  ```

## Build and publish the agent images from Jenkins

The Jenkins pipeline builds both agent images and pushes them to Docker Hub
with the Jenkins build number as the tag. It then uses those exact tags for
the on-demand Rocky and Ubuntu agent pods.

Before running the pipeline:

- Add a Jenkins **Username with password** credential with ID
  `dockerhub-creds`. Use your Docker Hub username and an access token as the
  password.
- Ensure the Jenkins Kubernetes cloud permits privileged pods: the image
  build stage runs Docker-in-Docker in a privileged sidecar.
- Ensure the resulting Docker Hub repositories are public, or configure
  Kubernetes image-pull credentials in the `jenkins` namespace for private
  repositories.

The pushed tags are `mannydevops/rocky9-net-tools-ci:<BUILD_NUMBER>` and
`mannydevops/ubuntu24.04-net-tools-ci:<BUILD_NUMBER>`. The Dockerfiles still
use their existing `V1.0` images as base images.

## Deploy Jenkins

Apply the namespace first, then the remaining Jenkins resources:

```sh
kubectl apply -f k8s/jenkins/namespace.yml
kubectl apply -f k8s/jenkins/agent-rbac.yml
kubectl apply -f k8s/jenkins/storage.yml
kubectl apply -f k8s/jenkins/jenkins-config.yml
kubectl apply -f k8s/jenkins/jenkins-deployment.yml
```

The Jenkins deployment installs the Kubernetes, Configuration as Code, Pipeline,
Git, and Credentials Binding plugins at startup. The Jenkins Kubernetes cloud
is configured to create agents in the `jenkins` namespace, using the controller's
service account.

Wait for Jenkins to become ready and open its NodePort service:

```sh
kubectl -n jenkins rollout status deployment/jenkins
minikube service jenkins-service -n jenkins
```

Complete Jenkins' initial setup, create a Pipeline job pointing at this
repository, and select **Pipeline script from SCM** so Jenkins reads the
repository's `Jenkinsfile`.

Each build creates one Rocky pod and one Ubuntu pod on demand. The plugin
removes those agent pods when their stages finish. Jenkins archives the RPM and
DEB files from the pod workspaces, so agents do not need a shared
`/mnt/artifacts` mount.
