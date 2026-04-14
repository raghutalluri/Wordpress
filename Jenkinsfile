pipeline {
  agent any

  environment {
    AWS_DEFAULT_REGION = 'ap-southeast-1'
    TF_IN_AUTOMATION   = 'true'
  }

  options {
    timestamps()
    ansiColor('xterm')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init') {
      steps {
        dir('terraform') {
          sh 'terraform init -input=false'
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          dir('terraform') {
            sh 'terraform apply -auto-approve -input=false'
          }
        }
      }
    }

    stage('Generate Ansible Inventory') {
      steps {
        sh 'python3 scripts/generate_ansible_config.py'
      }
    }

    stage('Run Ansible') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')]) {
          dir('ansible') {
            sh '''
              export ANSIBLE_HOST_KEY_CHECKING=False
              ansible-playbook -i inventory.ini playbook.yaml --private-key "$SSH_KEY"
            '''
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'ansible/inventory.ini, ansible/group_vars/all.yml', allowEmptyArchive: true
    }
  }
}
