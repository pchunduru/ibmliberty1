pipeline {
  agent any

  // Define flags for conditional execution
  environment {
    RUN_TERRAFORM = "true"   // set to "false" to skip Terraform
    RUN_ANSIBLE   = "true"   // set to "false" to skip Ansible
  }

  stages {

    stage('Terraform Provisioning') {
      when { expression { env.RUN_TERRAFORM == "true" } }
      steps {
        echo "Starting Terraform provisioning..."
        dir('terraform') {
          sh 'terraform init'
          sh 'terraform apply -auto-approve'
        }
      }
    }

    stage('Ansible Setup - Java & Liberty') {
      when { expression { env.RUN_ANSIBLE == "true" } }
      steps {
        echo "Installing Java 21 and IBM Liberty..."
        withCredentials([sshUserPrivateKey(credentialsId: 'libertypocpem', keyFileVariable: 'KEYFILE')]) {
          dir('ansible') {
            sh 'ansible-playbook -i inventory.ini setup-liberty.yml --private-key $KEYFILE'
          }
        }
      }
    }

    stage('Ansible Configuration - Controller') {
      when { expression { env.RUN_ANSIBLE == "true" } }
      steps {
        echo "Configuring Liberty Controller..."
        withCredentials([sshUserPrivateKey(credentialsId: 'libertypocpem', keyFileVariable: 'KEYFILE')]) {
          dir('ansible') {
            sh 'ansible-playbook -i inventory.ini controller.yml --private-key $KEYFILE'
          }
        }
      }
    }

    stage('Ansible Configuration - Member') {
      when { expression { env.RUN_ANSIBLE == "true" } }
      steps {
        echo "Configuring Liberty Member..."
        withCredentials([sshUserPrivateKey(credentialsId: 'libertypocpem', keyFileVariable: 'KEYFILE')]) {
          dir('ansible') {
            sh 'ansible-playbook -i inventory.ini member.yml --private-key $KEYFILE'
          }
        }
      }
    }

    stage('Terraform Destroy (Optional Cleanup)') {
      when { expression { env.RUN_TERRAFORM == "true" } }
      steps {
        echo "Cleaning up Terraform resources..."
        dir('terraform') {
          sh 'terraform destroy -auto-approve'
        }
      }
    }
  }

  post {
    success {
      echo "Pipeline completed successfully!"
    }
    failure {
      echo "Pipeline failed — check logs for details."
    }
  }
}
