variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  # No default - this is usually required per environment
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  # No default - required per environment
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  # No default - required per environment
}

variable "availability_zones" {
  description = "List of availability zones to use."
  type        = list(string)
  # No default - required per environment
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default     = {} # Default to no extra tags
}

variable "vpc_name" {
  description = "The name tag for the VPC."
  type        = string
  default     = "main-vpc" # Default name
}

variable "public_subnet_name_prefix" {
  description = "Prefix for the Name tag of public subnets."
  type        = string
  default     = "public-subnet" # Default prefix
}

variable "private_subnet_name_prefix" {
  description = "Prefix for the Name tag of private subnets."
  type        = string
  default     = "private-subnet" # Default prefix
}

variable "public_route_table_name" {
  description = "The name tag for the public route table."
  type        = string
  default     = "public-route-table" # Default name
}

variable "internet_gateway_name" {
  description = "The name tag for the Internet Gateway."
  type        = string
  default     = "main-internet-gateway" # Default name
}

variable "enable_nat_gateway" {
  description = "Set to true to create NAT Gateways for private subnets. Requires public subnets."
  type        = bool
  default     = true # Common requirement, default to true
}

variable "single_nat_gateway" {
  description = "Set to true to create a single NAT Gateway. If false, creates one per AZ."
  type        = bool
  default     = false # Default to one per AZ for high availability
}

variable "private_route_table_name_prefix" {
  description = "Prefix for the Name tag of private route tables."
  type        = string
  default     = "private-rt"
}

variable "nat_gateway_name_prefix" {
  description = "Prefix for the Name tag of NAT Gateways."
  type        = string
  default     = "nat-gw"
}

variable "elastic_ip_name_prefix" {
  description = "Prefix for the Name tag of Elastic IPs for NAT Gateways."
  type        = string
  default     = "nat-eip"
}
