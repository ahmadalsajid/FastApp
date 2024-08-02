# FastApp

## Status

![Development](https://github.com/ahmadalsajid/FastApp/actions/workflows/development.yml/badge.svg?branch=dev)
![Production](https://github.com/ahmadalsajid/FastApp/actions/workflows/production.yml/badge.svg?branch=main)


This is a simple Python FastAPI application that will be used to demonstrate
GitHub Actions for CI/CD, Docker Hub to publish the image, AWS ECS for deployment,
and Terraform for IaC.

We can separate the tasks in three main parts,

* Containerize the application with Docker
* Manage the infrastructure with Terraform
* Create CI/CD pipeline with GitHub Actions

## Docker

First, let's create a super simple Python FastAPI application that we can use
to manage with CI/C and deploy on AWS.
Create a directory [app](./app) with the files as below, you can refer to this
repository for the actual codes.

```
app
├── .dockerignore
├── Dockerfile
├── __init__.py
├── main.py
├── requirements.txt
└── test_main.py
```

You can use the [docker-compose.yaml](./docker-compose.yaml) to spin up a
container to test the application. It has only 2 APIs,

```
http://localhost:8000/
```

which returns the below response

```
{
    "Hello": "World"
}
```

And,

```
http://localhost:8000/greetings/{some_name}?q={some_optional_query}
```

that returns

```
{
    "Hello": "some_name",
    "q": "some_optional_query"
}
```

Let's spin up the application by

```
docker compose up -d
```

Once done with testing, remove with

```
docker compose down --rmi local
```

## Terraform

We have containerized the app. Now, we need to create the infrastructure to 
deploy them. We will use AWS ECS to host our application.  
Lets have a look at the [infrastructure](./infrastructure) directory.

```
./infrastructure
├── dev
│ ├── ecs
│ │ ├── .terraform.lock.hcl
│ │ ├── main.tf
│ │ ├── outputs.tf
│ │ └── variables.tf
│ └── vpc
│   ├── .terraform.lock.hcl
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
├── modules
│ ├── ecs
│ │ ├── 0-variables.tf
│ │ ├── 1-vpc.tf
│ │ ├── 2-security-groups.tf
│ │ ├── 3-load-balancer.tf
│ │ ├── 4-iam.tf
│ │ ├── 5-ecs.tf
│ │ ├── 6-outputs.tf
│ │ └── templates
│ │     └── ecs
│ │         └── app.json.tpl
│ └── vpc
│   ├── main.tf
│   ├── outputs.tf
│   └── variables.tf
└── prod
    ├── ecs
    | |── .terraform.lock.hcl
    │ ├── main.tf
    │ ├── outputs.tf
    │ └── variables.tf
    └── vpc
      |── .terraform.lock.hcl
      ├── main.tf
      ├── outputs.tf
      └── variables.tf
```

We can have an explanation for this. We will be creating 2 separate VPCs to
deploy our app, i.e., one for the `dev` environment, another one for the `prod`
environment. To keep our infrastructure safe, we will break it to the smallest 
modules possible. So, we will create the VPC and other ECS things separately.  
To do so, first, go to the [vpc](./infrastructure/dev/vpc) directory and update
the variables with your preferred/actual ones in the 
[variables.tf](./infrastructure/dev/vpc/variables.tf) file. After that, 
initialise by the command

```
terraform init
```

After initialising, create the resources by

```
terraform apply
```

Have patience, your VPC will spin up in a couple of minutes, please keep 
the VPC ID in the outputs to use in the later step.  
  
Once the VPC is up, now we will be creating the ECS cluster. Go to 
[ecs](./infrastructure/dev/ecs) directory and update the variables again in 
the file [variables](./infrastructure/dev/ecs/variables.tf) accordingly.
Rest of the process is same as before,

```
terraform init
terraform apply
```

> Keep in mind, this will launch resources in your AWS and if you forget 
> to clean up, it's going to cost you some money. So, please clean up the 
> environment every time you are done with testing, with the command 
> `terraform destroy` in the respective directories, i.e., 
> `infrastructure/dev/vpc/` and `infrastructure/dev/ecs//`


## GitHub Actions

Finally, we are at the end of our automation journey. We will create the CI/CD
pipeline with GitHub Actions. Let's create two YAML files where we are going 
to configure the pipelines for two different environments. The directory 
structure is 

```
.github
└── workflows
    ├── development.yml
    └── production.yml
```

The workflow is self-explanatory. BTW, you will need to create two environment
in your GitHub code repository's `settings` option, and set some variables 
and secrets i.e., Docker Hub username and token, AWS Credentials and so on to 
make this workflow work. We have two almost identical YML files, for development
and production environments respectively. We can have many more customizations
based on the needs.