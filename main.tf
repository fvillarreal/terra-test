terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

variable "bucket_name" {
  type    = string
  default = "my-fvillarreal-bucket"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"

  tags = {
    Name = "FernandoBucket"
    Envirnoment = "dev"
  }
}

resource "null_resource" "files" {
  provisioner "local-exec" {
    command = "echo $(date '+%Y-%m-%d_%H:%M:%S') | tee -a test1.txt test2.txt"
  }
}

resource "null_resource" "copy" {
  provisioner "local-exec" {
    command = "aws s3 sync ./ s3://${var.bucket_name}/ --exclude '*' --include 'test*.txt' &> output.txt"
  }
  depends_on = [aws_s3_bucket.bucket]
}

resource "null_resource" "verify" {
  provisioner "local-exec" {
    command = "aws s3 ls s3://${var.bucket_name} | awk '{print $3\" \"$4}' &> output.txt"
  }
  depends_on = [null_resource.copy]
}

data "local_file" "copy_output" {
  filename = "./output.txt"
  depends_on = [null_resource.verify]
}

output "copy_out" {
  value = data.local_file.copy_output.content
}

#resource "aws_s3_bucket_object" "filecopy" {
#  bucket = aws_s3_bucket.bucket.id
#  key    = "test1.txt"
#  acl = "private"
#  source = "./test1.txt"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
#  etag = filemd5("./test1.txt")
#}
