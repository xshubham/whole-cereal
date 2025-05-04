pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'book-library-api'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        DOCKER_REGISTRY = 'your-registry.azurecr.io'
        DOCKER_CREDENTIALS = 'docker-registry-credentials'
        TEST_DB_SERVER = 'localhost'
        TEST_DB_NAME = 'BookLibraryDB_Test'
        TEST_DB_USER = credentials('test-db-user')
        TEST_DB_PASSWORD = credentials('test-db-password')
        SONAR_PROJECT_KEY = 'book-library-api'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('application') {
                    sh '''
                        python -m venv venv
                        . venv/bin/activate
                        pip install -r requirements.txt
                    '''
                }
            }
        }

        stage('Static Code Analysis') {
            steps {
                dir('application') {
                    script {
                        // Install analysis tools
                        sh '''
                            . venv/bin/activate
                            pip install pylint bandit safety
                        '''
                        
                        // Run Pylint
                        sh '. venv/bin/activate && pylint src/ --output-format=parseable --fail-under=8.0 | tee pylint-report.txt || true'
                        
                        // Run Bandit security scan
                        sh '. venv/bin/activate && bandit -r src/ -f json -o bandit-report.json || true'
                        
                        // Check dependencies for known vulnerabilities
                        sh '. venv/bin/activate && safety check -r requirements.txt --json > safety-report.json || true'
                    }
                    
                    recordIssues(
                        tools: [
                            pylint(pattern: 'pylint-report.txt')
                        ]
                    )
                }
            }
        }

        stage('Unit Tests') {
            steps {
                dir('application') {
                    sh '''
                        . venv/bin/activate
                        python -m pytest tests/unit/ \
                            --junitxml=unit-test-results.xml \
                            --cov=src \
                            --cov-report=xml:unit-coverage.xml \
                            --cov-report=html:unit-coverage-html
                    '''
                }
            }
            post {
                always {
                    junit 'application/unit-test-results.xml'
                    cobertura coberturaReportFile: 'application/unit-coverage.xml'
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: 'application/unit-coverage-html',
                        reportFiles: 'index.html',
                        reportName: 'Unit Test Coverage Report'
                    ])
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('application') {
                    script {
                        // Scan Dockerfile
                        sh 'docker run --rm -i hadolint/hadolint < Dockerfile || true'
                        
                        // Build image
                        docker.build("${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}")
                    }
                }
            }
        }

        stage('Integration Tests') {
            steps {
                dir('application') {
                    script {
                        // Start test dependencies (e.g., test database)
                        sh 'docker-compose -f docker-compose.test.yml up -d db'
                        
                        // Wait for database to be ready
                        sh 'docker-compose -f docker-compose.test.yml run --rm wait-for-db'
                        
                        // Run integration tests
                        sh '''
                            . venv/bin/activate
                            TEST_DB_SERVER=${TEST_DB_SERVER} \
                            TEST_DB_NAME=${TEST_DB_NAME} \
                            TEST_DB_USER=${TEST_DB_USER} \
                            TEST_DB_PASSWORD=${TEST_DB_PASSWORD} \
                            python -m pytest tests/integration/ \
                                --junitxml=integration-test-results.xml \
                                --cov=src \
                                --cov-report=xml:integration-coverage.xml \
                                --cov-report=html:integration-coverage-html
                        '''
                    }
                }
            }
            post {
                always {
                    junit 'application/integration-test-results.xml'
                    cobertura coberturaReportFile: 'application/integration-coverage.xml'
                    publishHTML(target: [
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: 'application/integration-coverage-html',
                        reportFiles: 'index.html',
                        reportName: 'Integration Test Coverage Report'
                    ])
                    
                    // Clean up test dependencies
                    sh 'docker-compose -f docker-compose.test.yml down -v'
                }
            }
        }

        stage('Security Scan Container Image') {
            steps {
                script {
                    // Run Trivy vulnerability scanner
                    sh """
                        trivy image --format json --output trivy-report.json \
                        ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}
                    """
                    
                    // Optional: Fail build on HIGH or CRITICAL vulnerabilities
                    sh """
                        if trivy image --severity HIGH,CRITICAL --exit-code 1 \
                            ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}; then
                            echo 'No HIGH or CRITICAL vulnerabilities found'
                        else
                            echo 'HIGH or CRITICAL vulnerabilities found'
                            exit 1
                        fi
                    """
                }
            }
        }

        stage('Push Docker Image') {
            when {
                expression { 
                    currentBuild.resultIsBetterOrEqualTo('SUCCESS')
                }
            }
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_CREDENTIALS) {
                        docker.image("${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                        docker.image("${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}").push('latest')
                    }
                }
            }
        }

        stage('Update Kubernetes Manifests') {
            when {
                expression { 
                    currentBuild.resultIsBetterOrEqualTo('SUCCESS')
                }
            }
            steps {
                script {
                    sh """
                        sed -i 's|image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:.*|image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${DOCKER_TAG}|' k8s/apps/book-api/deployment.yaml
                        
                        git config user.email "jenkins@example.com"
                        git config user.name "Jenkins"
                        
                        git add k8s/apps/book-api/deployment.yaml
                        git commit -m "Update image tag to ${DOCKER_TAG}"
                        git push origin HEAD:main
                    """
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '''
                application/pylint-report.txt,
                application/bandit-report.json,
                application/safety-report.json,
                application/*-test-results.xml,
                application/*-coverage.xml,
                trivy-report.json
            ''', allowEmptyArchive: true
            
            cleanWs()
        }
        
        failure {
            emailext (
                subject: "Pipeline Failed: ${currentBuild.fullDisplayName}",
                body: """Pipeline failed at stage: ${currentBuild.description}
                Check console output at: ${env.BUILD_URL}""",
                recipientProviders: [culprits(), developers()]
            )
        }
    }
}