import spock.lang.*
@Library('jenkins-functions') _

class DeploymentJenkinsSpec extends Specification {

    def config = [
        functionName: 'connect',
        host: System.getenv('DEPLOYMENT_HOST') ?: 'localhost',
        user: System.getenv('DEPLOYMENT_USER') ?: 'ubuntu',
        sshKeyPath: System.getenv('SSH_KEY_PATH') ?: '/var/jenkins_home/.ssh/id_rsa',
        port: 22,
        timeout: 30
    ]

    def "Connect to deployment instance"() {
        when:
        def connection = this."${config.functionName}"([
            host: config.host,
            user: config.user,
            sshKeyPath: config.sshKeyPath,
            port: config.port,
            connectTimeout: config.timeout
        ])
        then:
        connection != null
        connection.isConnected()
    }

    @Unroll
    def "Reject invalid credentials: #caseDesc"() {
        when:
        this."${config.functionName}"(testConfig)
        then:
        thrown(AuthenticationException)
        where:
        caseDesc           | testConfig
        "invalid key"      | [host: config.host, user: config.user, sshKeyPath: "invalid/key/path", port: config.port, connectTimeout: 10]
        "invalid username" | [host: config.host, user: "invalid-username", sshKeyPath: config.sshKeyPath, port: config.port, connectTimeout: 10]
        "invalid host"     | [host: "0.0.0.0", user: config.user, sshKeyPath: config.sshKeyPath, port: config.port, connectTimeout: 10]
    }

}