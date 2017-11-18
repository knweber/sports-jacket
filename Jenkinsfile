pipeline {
  agent {
    dockerfile {
      filename 'Dockerfile.testing'
    }
    
  }
  stages {
    stage('Unit Tests') {
      steps {
        sh 'echo hello world; exit 1;'
      }
    }
  }
  environment {
    DATABASE_URL = 'postgres://ellie_dev_team:H4rdC4s3!99@ellie-production-v2.cabmxdxjziky.us-east-1.rds.amazonaws.com:5432/ellie_production'
    RECHARGE_ACCESS_TOKEN = '998616104d0b4668bcffa0cfde15392e'
    REDIS_URL = 'redis://localhost:6379/0'
    SHOPIFY_API_KEY = '59221049ec03849642bf3f1a00911f49'
    SHOPIFY_SHARED_SECRET = '31bba2a69efdd8cb77e5c6e3e6e9d3b6'
  }
}