pipeline {
    agent any

    // Two builds running at once would fight over the same deployment.
    options {
        disableConcurrentBuilds()
    }

    environment {
        IMAGE      = 'devops-demo'
        NAMESPACE  = 'devops-demo'
        DEPLOYMENT = 'devops-demo'
        CONTAINER  = 'app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                // This agent has Java but no Python, so the suite runs inside a
                // container built from the Dockerfile's `test` stage. Note the
                // deliberate absence of a -v bind mount: a path handed to
                // `docker run` resolves against the host filesystem, not this
                // workspace, so it would silently mount an empty directory.
                sh 'docker build --target test -t ${IMAGE}-test:${BUILD_NUMBER} .'
                sh 'docker run --rm ${IMAGE}-test:${BUILD_NUMBER}'
            }
        }

        stage('Build') {
            steps {
                // OrbStack shares its image store with Kubernetes, so the image
                // built here is immediately usable by pods. No registry, no push.
                sh 'docker build -t ${IMAGE}:${BUILD_NUMBER} .'
            }
        }

        stage('Deploy') {
            steps {
                sh 'kubectl -n ${NAMESPACE} set image deployment/${DEPLOYMENT} ${CONTAINER}=${IMAGE}:${BUILD_NUMBER}'
                sh 'kubectl -n ${NAMESPACE} rollout status deployment/${DEPLOYMENT} --timeout=180s'
            }
        }
    }

    post {
        success {
            echo "Deployed ${IMAGE}:${BUILD_NUMBER} to namespace ${NAMESPACE}"
        }
        always {
            // The test image is single-use; dropping it keeps the image store
            // from filling with one throwaway per build.
            sh 'docker rmi ${IMAGE}-test:${BUILD_NUMBER} || true'
        }
    }
}
