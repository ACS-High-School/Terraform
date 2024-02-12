variable "repository_names" {
  type    = list(string)
}

variable "image_tag_mutability" {
  type    = string
}

variable "encryption_type" {
  type    = string
}

variable "scan_on_push" {
  type    = bool
}
