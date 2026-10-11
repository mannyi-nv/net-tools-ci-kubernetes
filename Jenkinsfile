pipeline {
    agent none
    environment {
        R_IMG_NAME = "rocky9"
        U_IMG_NAME = "ubuntu24.04"
        IMG_TAG = "${BUILD_NUMBER}"
        R_IMAGE_FULL_NAME = "${R_IMG_NAME}:v0.${IMG_TAG}"
        U_IMAGE_FULL_NAME = "${U_IMG_NAME}:v0.${IMG_TAG}"
    }
    stages {
        stage('Build and Test') {
            parallel {

                stage('Rocky 9.8') {
                    agent { label 'rocky9.8' }
                    stages {
                        stage('Checkout') {
                            steps {
                                checkout scm
                            }
                        }
                        stage('Environment') {
                            steps {
                                sh '''
                                    echo "=== Printing Jenkins Environment ==="
                                    echo "NODE_NAME=$NODE_NAME"
                                    echo "NODE_LABELS=$NODE_LABELS"
                                    echo "WORKSPACE=$WORKSPACE"
                                    echo "BUILD_NUMBER=$BUILD_NUMBER"
                                    echo "JOB_NAME=$JOB_NAME"

                                    echo "=== scm Files Varification ==="
                                    ls -l
                                '''
                            }
                        }
                        stage('Test') {
                            steps {
                                sh '''
                                    docker build -t $R_IMAGE_FULL_NAME ./rocky
                                    docker run --rm \
                                        -e BUILD_NUMBER="$BUILD_NUMBER" \
                                        -v /mnt/artifacts:/artifacts \
                                        $R_IMAGE_FULL_NAME
                                '''
                            }
                        }
                    }
                    post {
                        always {
                            sh "docker rmi -f ${R_IMAGE_FULL_NAME}"
                        }
                    }
                }

                stage('Test buntu 24.04') {
                    agent { label 'ubuntu24.04' }
                    stages {
                        stage('Checkout') {
                            steps {
                                checkout scm
                            }
                        }
                        stage('Environment') {
                            steps {
                                sh '''
                                    echo "=== Printing Jenkins Environment ==="
                                    echo "NODE_NAME=$NODE_NAME"
                                    echo "NODE_LABELS=$NODE_LABELS"
                                    echo "WORKSPACE=$WORKSPACE"
                                    echo "BUILD_NUMBER=$BUILD_NUMBER"
                                    echo "JOB_NAME=$JOB_NAME"

                                    echo "=== scm Files Varification ==="
                                    ls -l
                                '''
                            }
                        }
                        stage('build') {
                            steps {
                                withCredentials([usernamePassword(
                                    credentialsId: 'dockerhub-creds',
                                    passwordVariable: 'PASS',
                                    usernameVariable: 'USERNAME'
                                )]) {
                                    sh '''
                                        echo $PASS | docker login -u $USERNAME --password-stdin
                                        echo "======= Pulling docker image ========"
                                        docker build -t ${U_IMAGE_FULL_NAME} ./ubuntu
                                        docker run --rm \
                                        -e BUILD_NUMBER=\"$BUILD_NUMBER\" \
                                        -v /mnt/artifacts:/artifacts \
                                        ${U_IMAGE_FULL_NAME}
                                    '''
                                }
                            }
                        }
                    } // Closed stages here properly
                    post {
                        always {
                            sh "docker rmi -f ${U_IMAGE_FULL_NAME}"
                        }
                    }
                }
            }
        } // Closed 'Build and Test' stages properly

        stage('Archive Artifacts') {
            agent { label 'linux' }
            steps {
                sh '''
                    echo "=== Preparing Jenkins Artifacts ==="

                    mkdir -p artifacts

                    cp -v /mnt/artifacts/build_$BUILD_NUMBER/* artifacts/

                    echo "=== Artifacts to Archive ==="
                    ls -lh artifacts/
                '''
                archiveArtifacts artifacts: 'artifacts/*', fingerprint: true
            }
        }
    }

    post {
        success {
            echo "========= build completed successfully ========="
        }
        failure {
            echo "========= build failed ========="
        }
    }
}