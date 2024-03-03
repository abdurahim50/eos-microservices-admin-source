//----------------------------------------------------------------

// Define the label for the Jenkins pod
def label = "build"

// Maven version to be used
def mvn_version = 'M2'

// Define the Pod template for Jenkins slave
podTemplate(label: label, yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: build
  annotations:
    sidecar.istio.io/inject: "false"
spec:
  containers:
  - name: build
    image: abdurahim/sre-jenkins-agent
    command:
    - cat
    tty: true
    volumeMounts:
    - name: dockersock
      mountPath: /var/run/docker.sock
  volumes:
  - name: dockersock
    hostPath:
      path: /var/run/docker.sock
"""
) {
    node (label) {
        // Stage: Checkout SCM
        stage ('Checkout SCM'){
          // Checkout code from Git repository
          git credentialsId: 'git', url: 'https://Abdurahim50@bitbucket.org/Abdurahim50/eos-micro-services-admin-source.git', branch: 'main'
          container('build') {
                stage('Build a Maven project') {
                  // Build Maven project
                  sh './mvnw clean package' 
                }
            }
        }

        // Stage: Artifactory configuration
        stage ('Artifactory configuration'){
          container('build') {
                stage('Artifactory configuration') {
                    // Configure Artifactory details
                    rtServer (
                    id: "jfrog",
                    url: "https://sre01.jfrog.io/artifactory",
                    credentialsId: "jfrog"
                )

                rtMavenDeployer (
                    id: "MAVEN_DEPLOYER",
                    serverId: "jfrog",
                    releaseRepo: "ed-libs-release-local",
                    snapshotRepo: "ed-libs-snapshot-local"
                )

                rtMavenResolver (
                    id: "MAVEN_RESOLVER",
                    serverId: "jfrog",
                    releaseRepo: "ed-libs-release",
                    snapshotRepo: "ed-libs-snapshot"
                )            
                }
            }
        }

        // Stage: Deploy Artifacts
        stage ('Deploy Artifacts'){
          container('build') {
                stage('Deploy Artifacts') {
                    // Deploy artifacts to Artifactory
                    rtMavenRun (
                    tool: "java", // Tool name from Jenkins configuration
                    useWrapper: true,
                    pom: 'pom.xml',
                    goals: 'clean install',
                    deployerId: "MAVEN_DEPLOYER",
                    resolverId: "MAVEN_RESOLVER"
                  )
                }
            }
        }

        // Stage: Publish build info
        stage ('Publish build info') {
            container('build') {
                stage('Publish build info') {
                    // Publish build info to Artifactory
                    rtPublishBuildInfo (
                        serverId: "jfrog"
                    )
               }
           }
       }

       // Stage: Docker Build
       stage ('Docker Build'){
          container('build') {
                stage('Build Image') {
                    // Build Docker image and push to Docker Hub
                    docker.withRegistry( 'https://registry.hub.docker.com', 'docker' ) {
                    def customImage = docker.build("abdurahim/eos-micro-services-admin:latest")
                    customImage.push()             
                    }
                }
            }
        }

        // Stage: Helm Chart
        stage ('Helm Chart') {
          container('build') {
            dir('charts') {
              withCredentials([usernamePassword(credentialsId: 'jfrog', usernameVariable: 'username', passwordVariable: 'password')]) {
              // Package Helm chart and push to Artifactory
              sh '/usr/local/bin/helm package micro-services-admin'
              sh '/usr/local/bin/helm push-artifactory micro-services-admin-1.0.tgz https://sre01.jfrog.io/artifactory/ed-helm-local --username $username --password $password'
              }
            }
          }
        }
    }
}



