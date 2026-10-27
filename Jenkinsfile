pipeline {
    agent none

    stages {
        stage('Build and Test') {
            parallel {
                stage('Build & Test Rocky 9.8') {
                    agent {
                        kubernetes {
                            cloud 'minikube'
                            defaultContainer 'rocky'
                            yaml '''
apiVersion: v1
kind: Pod
spec:
  automountServiceAccountToken: false
  containers:
  - name: rocky
    image: net-tools-rocky:local
    imagePullPolicy: Never
    command:
        - sleep
    arguments:
        - infinity
'''
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
                            yaml '''
apiVersion: v1
kind: Pod
spec:
  automountServiceAccountToken: false
  containers:
  - name: ubuntu
    image: net-tools-ubuntu:local
    imagePullPolicy: Never
    command:
        - sleep
    arguments:
        - infinity
'''
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
