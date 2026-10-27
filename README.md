# Net-tools CI on Minikube

Jenkins runs the Rocky and Ubuntu build/test stages concurrently in temporary
Kubernetes agent pods. The Rocky and Ubuntu images are built into Minikube
before a job runs; the pipeline does not need Docker on Jenkins or its agents.
RPM and DEB artifacts are archived by Jenkins from each agent workspace.

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

## Build the local agent images

Run these commands from the repository root whenever either Dockerfile or its
build script changes:

```sh
minikube image build -t net-tools-rocky:local ./rocky
minikube image build -t net-tools-ubuntu:local ./ubuntu
```

The images use the Rocky and Ubuntu base images in their respective Dockerfiles.
If the base images require registry authentication, authenticate the image
builder before building them.

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
and Git plugins at startup. The Jenkins Kubernetes cloud is configured to create
agents in the `jenkins` namespace, using the controller's service account.

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
