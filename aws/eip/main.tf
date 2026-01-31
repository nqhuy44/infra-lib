# --- Local variables ---
locals {
  create_eips = var.create ? var.number_of_eips : 0
}

# --- Elastic IPs ---
resource "aws_eip" "this" {
  count = local.create_eips

  domain               = "vpc"
  network_border_group = var.network_border_group
  public_ipv4_pool     = var.public_ipv4_pool

  # Associate with instance if specified and not using separate association
  instance = (var.associate_with_instance && !var.create_separate_association) ? try(var.instance_ids[count.index], null) : null

  # Associate with network interface if specified
  network_interface = var.network_interface_ids != null ? try(var.network_interface_ids[count.index], null) : null

  tags = merge(
    var.tags,
    var.eip_tags,
    {
      Name = var.eip_names != null ? var.eip_names[count.index] : "${var.name}-${count.index + 1}"
    }
  )

  lifecycle {}
}

# --- Separate EIP association (allows changing association without recreating the EIP) ---
resource "aws_eip_association" "this" {
  count = var.create && var.create_separate_association && var.instance_ids != null ? min(local.create_eips, length(var.instance_ids)) : 0

  allocation_id = aws_eip.this[count.index].id
  instance_id   = var.instance_ids[count.index]
}