title: 如何使用Docker来部署持久的Jenkins服务
date: 2020-04-09 19:57:09
---

这篇文章分享一下如何用 Docker 来部署 Jenkins，还有如何在 Docker Jenkins 中使用 pipeline 配置项目


## 启动 Docker
首先需要启动 Docker jenkins，这一步十分简单，但是需要一些参数
``` bash
docker run -d -v jenkins_home:/var/jenkins_home -p 8012:8080 -v /var/run/docker.sock:/var/run/docker.sock --name jenkins -u 0 -e TZ="Asia/Shanghai" jenkins/jenkins:lts
```

- **-v jenkins_home:/var/jenkins_home** 是挂载本地空间目录，这个如果不挂载的话，重启 Docker 容器里面的数据就没了
- **-p 8012:8080** 映射端口到本地 8012
- **-u 0** 指定 Docker 容器以 root 用户运行（注意！：这样做十分不安全，因为我是在虚拟机上操作，所以用的 root 用户，这样也需要启动 root 用户的 docker。非 root 用户运行千万不要加这个参数）
- **-e TZ="Asia/Shanghai"** 指定时区环境变量
- **-v /var/run/docker.sock:/var/run/docker.sock** 挂载宿主 Docker 的 sock 文件

上面的启动参数，其中最重要的是最后的一个，就是把属主机的 docker sock文件挂载到 Docker Jenkins 里面，因为这样才能让在 Pipeline 中使用 Docker 来进行构建。

当然，有些极客朋友可能会说，那我直接在 Docker 中运行 Docker 也可以嘛，但是 Docker 中套 Docker 其实更难搞，而且有很多坑。

甚至 Docker 的一名贡献者也专门写过文章来
https://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/


## 连接宿主机 docker
既然我们不会在 Jenkins Docker 容器中启动 Docker 服务，那么就只能通过 socket 的方式连接一个启动好的 Docker 服务，

![docker_configure](./run-jenkins-in-docker/WX20200901-210840@2x.png)

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