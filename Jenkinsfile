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

    stage('Terraform Plan') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          dir('terraform') {
            sh 'terraform plan -input=false -out=tfplan'
          }
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          dir('terraform') {
            sh 'terraform apply -auto-approve tfplan'
          }
        }
      }
    }

    stage('Generate Ansible Inventory') {
      steps {
        sh 'python3 python/generate_ansible_config.py'
      }
    }

    stage('Run Ansible Validation') {
      steps {
        withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')]) {
          sh '''
            export ANSIBLE_HOST_KEY_CHECKING=False
            ansible-playbook -i ansible/inventory.ini ansible/playbook.yaml --private-key "$SSH_KEY"
          '''
        }
      }
    }
  }
}
