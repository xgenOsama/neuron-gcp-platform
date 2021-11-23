variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tenant" {
  type = string
}

variable "environment" {
  type = string
}

variable "program" {
  type = string
}

variable "stage" {
  type = string
}

variable "compute_project" {
  type = string
}

variable "additional_local_markets" {
  type = list(string)
}

variable "disable_qlik_accounts" {
  type = list(string)
}

variable "enable_new_qlik_sa" {
  type = list(string)
}

variable "add_permission" {
  type = string
}

variable "compute_project_program" {
  type = string
}

variable "additional_access" {
  type = list(string)
  default = []
}
