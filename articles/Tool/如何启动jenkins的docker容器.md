title: 如何启动Jenkins的docker容器
date: 2020-04-09 19:57:09

---

ocker run -d -v jenkins_home:/var/jenkins_home -p 8012:8080 -v /var/run/docker.sock:/var/run/docker.sock --name jenkins -u 0 -e TZ="Asia/Shanghai" jenkins/jenkins:lts

jenkinsfile
``` jenkinsfile
pipeline {
    agent none

    triggers {
        pollSCM('*/1 * * * *')
    }
     environment {
        HOME = '.'
        JFISH_DATASOURCE_RDS_DATABASE_URL = credentials('jenkins-jfish-datasource-rds-database_url')
        GOPROXY = 'goproxy.cn'
        DOCKER_REGISTER = 'fwchen'
        JFISH_STORAGE_ENDPOINT = credentials('s3_storage_endpoint')
        JFISH_STORAGE_ACCESS_KEY_ID = credentials('s3_storage_access_key_id')
        JFISH_STORAGE_SECRET_ACCESS_KEY_ID = credentials('s3_storage_secret_access_key_id')
        docker_hub_username = credentials('docker_hub_username')
        docker_hub_password = credentials('docker_hub_password')
    }
    stages {
        stage('Lint') {
            agent {
                docker {
                    image 'golangci/golangci-lint:latest'
                }
            }
            steps {
                sh 'golangci-lint run -v'
            }
        }
        stage('Test') {
            agent {
                docker {
                    image 'golang:1.13.4-stretch'
                }
            }
            steps {
                sh 'make test'
            }
        }
        stage('Build') {
            agent {
                docker {
                    image 'golang:1.13.4-stretch'
                }
            }
            steps {
                sh 'make build'
            }
        }
        stage('Build Tools') {
            agent {
                docker {
                    image 'golang:1.13.4-stretch'
                }
            }
            steps {
                sh 'make build-tool'
            }
        }
        stage('Dockerize') {
            agent {
                docker {
                    image 'docker:19.03.5'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            stages {
                stage('Build Image') {
                    steps {
                        sh "cd migration && docker build . -t $DOCKER_REGISTER/jellyfish-migration:latest"
                        sh "docker build . -f cmd/jellyfish-tool/Dockerfile -t $DOCKER_REGISTER/jellyfish-tool:latest"
                        sh "docker build . -t $DOCKER_REGISTER/jellyfish:latest"
                    }
                }
                stage('Registry Login') {
                    steps {
                        sh "echo $docker_hub_password | docker login -u $docker_hub_username --password-stdin"
                    }
                }
                stage('Publish image') {
                    steps {
                        sh 'docker push $DOCKER_REGISTER/jellyfish:latest'
                        sh 'docker push $DOCKER_REGISTER/jellyfish-migration:latest'
                        sh 'docker push $DOCKER_REGISTER/jellyfish-tool:latest'
                        sh 'echo "$DOCKER_REGISTER/jellyfish:latest" > .artifacts'
                        sh 'echo "$DOCKER_REGISTER/jellyfish-migration:latest" >> .artifacts'
                        sh 'echo "$DOCKER_REGISTER/jellyfish-tool:latest" >> .artifacts'
                        archiveArtifacts(artifacts: '.artifacts')
                    }
                }
                stage('Remove image') {
                    steps {
                        sh "docker image rm $DOCKER_REGISTER/jellyfish:latest"
                        sh "docker image rm $DOCKER_REGISTER/jellyfish-migration:latest"
                        sh "docker image rm $DOCKER_REGISTER/jellyfish-tool:latest"
                    }
                }
            }
        }
    }
    post {
        always {
            rocketSend currentBuild.currentResult
        }
    }
}
```