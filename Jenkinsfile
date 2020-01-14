pipeline {
    agent none
    triggers {
        pollSCM('*/1 * * * *')
    }
    environment {
        DOCKER_REGISTER = credentials('jenkins-blog-docker-register')
    }
    stages {
        stage('Npm install') {
            agent {
                docker {
                    image 'node:12.14.0-stretch'
                }
            }
            steps {
                sh 'npm install'
            }
        }
        stage('Theme install') {
            agent {
                docker {
                    image 'node:12.14.0-stretch'
                }
            }
            steps {
                sh 'cd node_modules/@starfishx/theme-hg && npm install'
            }
        }
        stage('Build') {
            agent {
                docker {
                    image 'node:12.14.0-stretch'
                }
            }
            steps {
                sh './node_modules/.bin/starfish render . --output="blog-dist"'
            }
        }
        stage('Build ssr') {
            agent {
                docker {
                    image 'node:12.14.0-stretch'
                }
            }
            steps {
                sh './node_modules/.bin/starfish angular-ssr .'
            }
        }
        stage('Dockerize') {
            agent {
                docker {
                    image 'docker:19.03.5'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh "ls"
                sh "docker build . -t $DOCKER_REGISTER/fangwei-blog:v0.0.$BUILD_NUMBER"
            }
        }
        stage('Publish image') {
            agent {
                docker {
                    image 'docker:19.03.5'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh 'docker push $DOCKER_REGISTER/fangwei-blog:v0.0.$BUILD_NUMBER'
                sh 'echo "$DOCKER_REGISTER/fangwei-blog:v0.0.$BUILD_NUMBER" > .artifacts'
            }
        }
        stage('Remove image') {
            agent {
                docker {
                    image 'docker:19.03.5'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                sh "docker image rm $DOCKER_REGISTER/fangwei-blog:v0.0.$BUILD_NUMBER"
            }
        }
    }
    post {
        always {
            rocketSend currentBuild.currentResult
        }
        success {
            archiveArtifacts(artifacts: './.artifacts')
        }
    }
}