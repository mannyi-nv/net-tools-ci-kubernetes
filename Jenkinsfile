pipeline {
    agent none
    environment {
        R_IMG_NAME = "rocky9"
        U_IMG_NAME = "ubuntu24.04"
        IMG_TAG = "${BUILD_NUMBER}"
        R_IMAGE_FULL_NAME = "${R_IMG_NAME}:v0.${IMG_TAG}"
        U_IMAGE_FULL_NAME = "${U_IMG_NAME}:v0.${IMG_TAG}"
        ITAY_DOCKERHUB_PASS = "dckr_pat_kTSQXKzjM4r2WshQv6Rp95EwFtM" // Note: It is safer to store tokens in credentials instead of hardcoding
        ITAY_DOCKERHUB_USER = "itaylevops"
    }
    stages {
        stage('Build and Test') {
            parallel {

                stage('Build & Test Rocky 9.8') {
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
                        stage('Build') {
                            steps {
                                withCredentials([usernamePassword(
                                    credentialsId: 'net-tools-ci-dev-3',
                                    passwordVariable: 'ITAY_DOCKERHUB_PASS',
                                    usernameVariable: 'ITAY_DOCKERHUB_USER'
                                )]) {
                                    sh """ echo $ITAY_DOCKERHUB_PASS | docker login -u $ITAY_DOCKERHUB_USER --password-stdin """
                                    echo "======= Pulling docker image ========"
                                    sh "docker build -t ${R_IMAGE_FULL_NAME} ./rocky"
                                    sh "docker run --rm \
                                        -e BUILD_NUMBER=\"$BUILD_NUMBER\" \
                                        -v /mnt/artifacts:/artifacts \
                                        ${R_IMAGE_FULL_NAME}"
                                }
                            }
                        }
                    }
                    post {
                        always {
                            sh "docker rmi -f ${R_IMAGE_FULL_NAME}"
                        }
                    }
                } // End of Rocky stage

                stage('Build & Test buntu 24.04') {
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
                                    sh """ echo $PASS | docker login -u $USERNAME --password-stdin """
                                    echo "======= Pulling docker image ========"
                                    sh "docker build -t ${U_IMAGE_FULL_NAME} ./ubuntu"
                                    sh "docker run --rm \
                                        -e BUILD_NUMBER=\"$BUILD_NUMBER\" \
                                        -v /mnt/artifacts:/artifacts \
                                        ${U_IMAGE_FULL_NAME}"
                                }
                            }
                        }
                    }
                    post {
                        always {
                            sh "docker rmi -f ${U_IMAGE_FULL_NAME}"
                        }
                    }
                } // End of Ubuntu stage

            }
        } // End of 'Build and Test' stage

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
    } // End of main stages block

    post {
        success {
            echo "========= build completed successfully ========="
        }
        failure {
            echo "========= build failed ========="
        }
    }
}