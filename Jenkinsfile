pipeline {
    agent none

    stages {
        stage('Build and Push Agent Images') {
            agent {
                kubernetes {
                    cloud 'minikube'
                    defaultContainer 'docker'
                    yaml '''
apiVersion: v1
kind: Pod
spec:
  automountServiceAccountToken: false
  containers:
  - name: docker
    image: docker:27.5.1-cli
    command:
    - sh
    - -c
    - cat
    tty: true
    env:
    - name: DOCKER_HOST
      value: tcp://localhost:2375
  - name: dind
    image: docker:27.5.1-dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
    args:
    - --host=tcp://0.0.0.0:2375
    - --host=unix:///var/run/docker.sock
'''
                }
            }
            steps {
                checkout scm
                timeout(time: 2, unit: 'MINUTES') {
                    sh '''
                        until docker info >/dev/null 2>&1; do
                            echo "Waiting for Docker-in-Docker daemon..."
                            sleep 2
                        done
                    '''
                }
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKERHUB_USERNAME',
                    passwordVariable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''
                        set -eu
                        echo "$DOCKERHUB_TOKEN" | docker login \
                            --username "$DOCKERHUB_USERNAME" \
                            --password-stdin

                        docker build --pull \
                            --tag "mannydevops/rocky9-net-tools-ci:${BUILD_NUMBER}" \
                            ./rocky
                        docker push "mannydevops/rocky9-net-tools-ci:${BUILD_NUMBER}"

                        docker build --pull \
                            --tag "mannydevops/ubuntu24.04-net-tools-ci:${BUILD_NUMBER}" \
                            ./ubuntu
                        docker push "mannydevops/ubuntu24.04-net-tools-ci:${BUILD_NUMBER}"
                    '''
                }
            }
        }

        stage('Build and Test') {
            parallel {
                stage('Build & Test Rocky 9.8') {
                    agent {
                        kubernetes {
                            cloud 'minikube'
                            defaultContainer 'rocky'
                            yaml """
apiVersion: v1
kind: Pod
spec:
  automountServiceAccountToken: false
  containers:
  - name: rocky
    image: mannydevops/rocky9-net-tools-ci:${env.BUILD_NUMBER}
    imagePullPolicy: Always
    command:
        - sleep
    args:
        - infinity
"""
                        }
                    }
                    steps {
                        checkout scm
                        sh '''
                            echo "Building using on-demand Kubernetes agent: $NODE_NAME"
                            ./rocky/net-tools-build.sh
                        '''
                        archiveArtifacts artifacts: 'artifacts/rocky/*.rpm', fingerprint: true
                    }
                }

                stage('Build & Test Ubuntu 24.04') {
                    agent {
                        kubernetes {
                            cloud 'minikube'
                            defaultContainer 'ubuntu'
                            yaml """
apiVersion: v1
kind: Pod
spec:
  automountServiceAccountToken: false
  containers:
  - name: ubuntu
    image: mannydevops/ubuntu24.04-net-tools-ci:${env.BUILD_NUMBER}
    imagePullPolicy: Always
    command:
        - sleep
    args:
        - infinity
"""
                        }
                    } 
                    steps {
                        checkout scm
                        sh '''
                            echo "Building using on-demand Kubernetes agent: $NODE_NAME"
                            ./ubuntu/net-tools-build.sh
                        '''
                        archiveArtifacts artifacts: 'artifacts/ubuntu/*.deb', fingerprint: true
                    }
                }
            }
        }
    }

    post {
        success {
            echo '========= build completed successfully ========='
        }
        failure {
            echo '========= build failed ========='
        }
    }
}
