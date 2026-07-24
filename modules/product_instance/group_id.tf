data "gitlab_group" "this" {
  count     = var.group_id == "" && var.group_path != "" ? 1 : 0
  full_path = var.group_path
}

locals {
  resolved_group_id = var.group_id != "" ? var.group_id : (
    var.group_path != "" ? tostring(data.gitlab_group.this[0].id) : ""
  )
}
