- [1. initialize](#1-initialize)
  - [1.1 Download terraform](#11-download-terraform)
  - [1.2 Init](#12-init)
- [2. Resources](#2-resources)
- [3. Providers](#3-providers)
  - [3.1 Set up provider](#31-set-up-provider)
  - [3.2 Multiple providers to allow multiple regions](#32-multiple-providers-to-allow-multiple-regions)
- [4. Data source](#4-data-source)
  - [4.1 How to use data source](#41-how-to-use-data-source)
  - [4.2 Why use data source](#42-why-use-data-source)
- [5. Outputs](#5-outputs)
- [6. Locals](#6-locals)
- [7. Files](#7-files)
  - [7.1 Files as input](#71-files-as-input)
  - [7.1 templateFile Function for Files](#71-templatefile-function-for-files)
  - [7.2 Template loops](#72-template-loops)
- [8. Variables](#8-variables)
  - [8.1 Variable for user prompt](#81-variable-for-user-prompt)
  - [8.2 Variable defaults](#82-variable-defaults)
  - [8.3 Setting variables](#83-setting-variables)
    - [8.3.1 Setting variable in command line](#831-setting-variable-in-command-line)
    - [8.3.2 Setting variable using environment variable](#832-setting-variable-using-environment-variable)
    - [8.3.3 Setting variable using file](#833-setting-variable-using-file)
  - [8.4 Variable types](#84-variable-types)
    - [8.4.1 Type constraint](#841-type-constraint)
    - [8.4.2 3 Simple Types](#842-3-simple-types)
    - [8.4.3 Complex types](#843-complex-types)
      - [8.5.3.1 List type](#8531-list-type)
      - [8.5.3.2 Set type](#8532-set-type)
      - [8.5.3.3 Tuple type](#8533-tuple-type)
      - [8.5.3.4 Map type](#8534-map-type)
      - [8.5.3.5 Object type](#8535-object-type)
      - [8.5.3.6 Any](#8536-any)
- [9. Project Layout](#9-project-layout)
  - [9.1 Project folders](#91-project-folders)
  - [9.2 Naming convention](#92-naming-convention)
- [10. Modules](#10-modules)
  - [10.1 Child folders](#101-child-folders)
  - [10.2 Remote modules](#102-remote-modules)
  - [11](#11)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>


# 1. initialize
## 1.1 Download terraform
For windows put location of terraform.exe in environment variable path
## 1.2 Init
go to working directory
```
terraform init
```

# 2. Resources
Represent thing in the infrastructure.

https://registry.terraform.io/providers/hashicorp/aws/latest/docs

```
resource "aws_s3_bucket" "name_of_resource" {
    bucket = "mandatory_unique_name_of_bucket"
    acl = "private"
}
```

We can look at attribute section of a resource to get the output of a created resource's attribute as input for another resource

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource_type.resource_identifier.attribute_name

example

```
resource "aws_security_group" "liny_security_group" {
    vpc_id = aws_vpc.liny_vpc.id
    name = " liny security group"
}
```

# 3. Providers

## 3.1 Set up provider
A provider has to provide terraform a way to create, read, and delete.

Providers are not part of main terraform source code, and they are in separate binaries in their own repos. 

After running terraform init, they are downloaded and are binaries inside .terraform folder

example

```
provider "aws" {
    region = "us-east-2"

```

specifying a required provider with version ~> in the required_providers block will allow any version >= 4 but less than 5. to be allowed. 

Version constraints is not needed to be worried about if .terraform.lock.hcl is committed to git.

```
terraform {
  required_providers {
    aws = {
      version = "~> 4.0"
    }
  }
}

```

## 3.2 Multiple providers to allow multiple regions
To allow aws to do multiple regions, just use multiple provider blocks

for a resource that doesn't have a provider=aws.alia then terraform will pick the provider without an alias.

```
provider "aws" {
    region = "us-east-1"
}

provider "aws" {
    region = "us-east-2"
    alias = "ohio"
}

resource "aws_vpc" "virginia_vpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "ohio_vpc" {
    cidr_block = "10.1.0.0/16"
    provider = aws.ohio
}
```

# 4. Data source

## 4.1 How to use data source
Data source is used in terraform to fetch data from a resource that is not managed by the current terraform proj; basically like read-only resources that already exists so we can read its specific properties.

below example sets a resource iam policy to give rights to a bucket not part of this tf.
```
provider "aws" {
    region = "es-east-2"
}

data "aws_s3_bucket" "yl-bucket" {
    bucket = "yl-bucket"
}

resource "aws_iam_policy" "my_bucket_policy" {
    name = "my-bucket-policy"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:ListBucket"
            ],
            "Effect": "Allow",
            "Resource": [
                "${data.aws_s3_bucket.yl-bucket.arn}"
            ]
        }
    ]
}
EOF
}
```

for any multi-line use, 
```
<<LABEL 
    multi line stuff
    stuff
LABEL
```

to get data injected into multi-line, we have to use interpolation
```
${ }
```

## 4.2 Why use data source
When large tf projects are broken into smaller projects, data sources allow easier reference of data than hard coding certain things, and we can allow terraform to fail if resource source doesn't exist

It's also useful for migrating, and tell terraform about dependencies so it fails when it needs to.

# 5. Outputs
Output in tf projects show data after tf successfully completes. Outputs are useful for allowing us to echo values from the tf run to the cmd line. 

```
output "message" {
    value = "Test Message"
}
```
```
provider "aws" {
    region = "us-west-2"
}

resource "aws_s3_bucket" "yl_bucket_1" {
    bucket = "yl_bucket_1"
}

output "bucket_name" {
    value = aws_s3_bucket.yl_bucket_1.id
}

output "bucket_arn" {
    value = aws_s3_bucket.yl_bucket_1.arn
}

output "bucket_information" {
    value = "bucket name: ${aws_s3_bucket.yl_bucket_1.id}, bucket arn: ${aws_s3_bucket.yl_bucket_1.arn}"
}
```

can just output everything about the resource by not specifying an attribute
```
output "all" {
  value = aws_s3_bucket.yl_bucket_1
}
```

# 6. Locals
Locals are basically variables in other programming languages.

variables in terraforms are more like 'inputs'

locals can also reference output of a resource
```
provider "aws" {
    region = "us-east-2"
}

locals {
    first_part = "hello"
    second_part = "${local.first_part}-world"
    bucket_name = "${local.second_part}-var"
}

resource "aws_s3_bucket" "bucket" {
    bucket = local.bucket_name
}

```

# 7. Files
## 7.1 Files as input
Similar to locals, files can be used as inputs.

```
provider "aws" {
    region = "us-east-2"
}

resource "aws_iam_policy" "yl_bucket_policy" {
    name = "list-buckets-policy"
    policy = file("./policy.iam")
}
```

where policy.iam =
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
            "s3:ListBucket"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
```

## 7.1 templateFile Function for Files
To use dynamic values in a file, use the templateFile function to pass the values into the file, then use the file to set the local.

```
locals {
    rendered = templatefile("./template.tpl", { firstname = "y", lastname = "l", number = 1})
}

output "rendered_template" {
    value = local.rendered
}
```

template.tpl
```
hello world ${firstname} ${lastname} ${number}
```

## 7.2 Template loops
The template file can use loops to dynamically build contents

main.tf
```
output "rendered_template" {
    value = templatefile("./temp.tpl", { port = 443, ip_addrs = ["10.0.0.1", "10.0.0.2"] })
}
```

temp.tpl
```
%{ for addr in ip_addrs ~}
backend ${addr}:${port}
%{ endfor ~}
```

# 8. Variables

Note, unlike locals which are more like variables in other languages, variable cannot be set to the output of a resource attribute.

variables in tf are more like input variables.

## 8.1 Variable for user prompt
Variables can be set at runtime.

When running the tf below, terraform will pause and ask for value of the variable.
```
provider "aws" {
    region = "us-east-2"
}

variable "bucket_name" {
    description = "bucket name
}

rresource "aws_s3_bucket" "bucket" {
    bucket = var.bucket_name
}
```

## 8.2 Variable defaults

Setting a default on a variable means if no value is provided for that variable, then the default is used.

To set the value
```
terraform apply -var="image_id=ami-abc123"
```

Example of default
```
variable "some_variable" {
    default = "xxxx"
}

or

variable some_variable {
    default = "xxxx"
}
```

## 8.3 Setting variables
### 8.3.1 Setting variable in command line
use the -var option flag
```
terraform apply -var variablename=somevalue
```

### 8.3.2 Setting variable using environment variable
To use environment variables as values for variables for terraform, use
TF_VAR_variableidentifier format
```
export TF_VAR_variablename=somevalue
```

### 8.3.3 Setting variable using file
Use a 'terraform.tfvars' file, which is a filename terraform looks at to discover vlaues for variables.

If we want to use other filenames, we have to end the extension with .auto.tfvars. Using this technique, we can split the variables into multiple .auto.tfvars files.

Inside terraform.tfvars
```
bucket_name = "yl_bucket"
bucket_num = "12345"
```

main.tf
```
provider "aws" {
    region = "us-east-2"
}

variable "bucket_name" {
    description = "bucket name"
}

variable "bucket_number" {
    default = "12"
}

resource "aws_s3_bucket" "bucket" {
    bucket = "${var.bucket_Name}${var.bucket_number}"
}
```

## 8.4 Variable types
using a map {}
```
variable "instance_map" {}
variable "env_type" {}

output "selected_instance" {
    value = var.instance_map[var.environment_type]
}
```

terraform.tfvars
```
instance_map = {
    dev = "t3.small"
    test = "t3.medium"
    prod = "t3.large"
}

environment_type = "test"
```
### 8.4.1 Type constraint
If we use 'type' constraint, we will force only specific types to be passed in for variables. Terraform will print errors if type constraint is violated.

### 8.4.2 3 Simple Types
* string
* number
  * Allow any number with or without quotes
* bool
  * true
  * false
  * “true”
  * "false"
  * "1" (evaluated to true)
  * "0" (evaluated to false)

```
variable "a" {
    type = string
    default = "somevalue"
}

variable "b" {
    type = bool
    default = true
}

variable "c" {
    type = number
    default = 1
}
```

### 8.4.3 Complex types
The complex types can use other simple or complex types.
```
list(<TYPE>)
set(<TYPE>)
map(<TYPE>)
object()
tuple([<TYPE>, …])
```

#### 8.5.3.1 List type
```
variable "a" {
    type = list(string)
    default = ["foo", "bar", "zoo"]
}

output "a" {
    value = var.a
}

output "b" {
    value = element(var.a, 1)
}

output "c" {
    value = length(var.a)
}
```

#### 8.5.3.2 Set type

Below is a use of set. Set will only keep uniques, so [1, 2, 2] will be reduced to [1, 2]

Lists can be converted to set to enforce uniqueness, such that toset will return just ["foo"] in example below
```
variable "set" {
    type = set(number)
    default = [1, 2, 2]
}

variable "list" {
    type = list(string)
    default = ["foo", "foo", "foo"]
}

output "set" {
    value = var.set
}

output "list" {
    value = var.list
}

output "list_to_set" {
    value = toset(var.list)
}
```

#### 8.5.3.3 Tuple type
Tuple is collection of one or more values. 
```
variable "tuple" {
    type = tuple([string, number, bool])
    default = ["four", 4, true]
}

output "tuple" {
    value = var.tuple
}
```

#### 8.5.3.4 Map type
Set of values indexed by key. the type of the map is the type of the value of the key-value pair
```
variable "map" {
    type = map(number)
    default = {
        "one" = 1
        "two" = 2
    }
}

output "map" {
    value = var.map
}

output "map_one" {
    value = var.map["one"]
}
```

#### 8.5.3.5 Object type
Object is a data structure that can be defined with other types.

properties can be objects too
```
variable "dog" {
    type = object({ name = string, breed = string, age = number})
    default = {
        name = "Buddy"
        breed = "Corgi"
        age = 1
    }
}

output "dog" {
    value = var.dog
}

```

#### 8.5.3.6 Any
Any is a placeholder and not an actual type. Terraform will calculate the type at runtime when any is used.

Below example, terraform will try to determine the type of any by looking at the default

```
variable "any" {
    type = any
    default = {
        name = "name"
        value = "value"
    }
}

output "any" {
    value = var.any
}
```

# 9. Project Layout
Terraform only cares that files end in .tf, it doesn't need 'main'.tf

## 9.1 Project folders
All files must be in the same folder.

The top-level folder is the main terraform project, and all files at that level are considered part of the project.

## 9.2 Naming convention
* Providers are set up in a file called main.tf
* Files are broken up around diff areas of the system

# 10. Modules
Modules are folders containing grouped terraform resources, variables, outputs, etc. Every terraform has atleast one module: the root module.

## 10.1 Child folders
Terraform use child folders to create modules, which are terraform projects that contain all the same constructs as main terraform projects. They're used as reusable blocks of teraform code that can exist as many instances within main terraform block.

main.tf
```
provider "aws" {
    region = "us-east-2"
}

module "work_queue" {
    source = "./sqs"
    queue_name = "work"
}

output "work_queue_name" {
    value = module.work_queue.queue_name
}
```

/sqs/variables.tf
```
variable "queue_name" {
    description = "name"
}

variable "max_receive_count"{
    description = "The maximum number of times that a message can be received by consumers"
    default = 5
}

variable "visibility_timeout" {
    default = 30
}

```

/sqs/output.tf

output of modules can be used by caller's .tf
```
output "queue_arn" {
    value = aws_sqs_queue.sqs.arn
}

output "queue_name" {
    value = aws_sqs_queue.sqs.name
}

output "dead_letter_queue_arn" {
    value = aws_sqs_queue.sqs_dead_letter.arn
}

output "dead_letter_queue_name" {
    value = aws_sqs_queue.sqs_dead_letter.name
}

```
/sqs/main.tf
```
resource "aws_sqs_queue" "sqs" {
    name = "awesome_co-${var.queue_name}"
    visibility_timeout_seconds = var.visibility_timeout
    delay_seconds = 0
    max_message_size = 262144
    message_retention_seconds = 345600 # 4 days.
    receive_wait_time_seconds = 20 # Enable long polling
    redrive_policy = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.sqs_dead_letter.arn}\",\"maxReceiveCount\":${var.max_receive_count}}"
}

resource "aws_sqs_queue" "sqs_dead_letter" {
    name = "awsome_co-${var.queue_name}-dead-letter"
    delay_seconds = 0
    max_message_size = 262144
    message_retention_seconds = 1209600 # 14 days.
    receive_wait_time_seconds = 20
}

```

If we want to return the full objects from the module, then in the module output.tf, just return the object itself instead of individual attributes.

We can also take entire resources as inputs

## 10.2 Remote modules
Remote modules are modules hosted externally to local file system. Supported remote module sources include github, s3.

Be careful with remote module's versioning. best practice would be setting explicit versioning using git tags. ?ref=0.0.1

https is inplicit for git if not specified.
```
provider "aws" {
    region = "us-east-2"
}

module "work_queue" {
    source = "github.com/ylin36/sample-module"
    queue_name = "work-queue"
}

output "work_queue" {
    value = module.work_queue.queue
}
```

## 11