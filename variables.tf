variable "region" {
  type = string
}

variable "ami" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "key" {
  type = map(any)
}

variable "bucket_name" {
  type = string
}
