# When template_id is not given, default to the newest Debian template Hostinger
# offers (resolved by name, so there is no fragile hardcoded catalog id). The
# data source runs only when this module is instantiated (the caller gates it
# behind `enable`), so a dormant plan never calls the Hostinger API.
data "hostinger_vps_templates" "available" {
  count = var.template_id == null ? 1 : 0
}

# When data_center_id is not given, resolve it from a human region string
# (matched against the data center name/city/location/continent) so callers
# pick "Brazil" / "São Paulo" instead of a magic catalog id. Gated like the
# template lookup, so a dormant plan never calls the Hostinger API.
data "hostinger_vps_data_centers" "available" {
  count = var.data_center_id == null ? 1 : 0
}

locals {
  region_match_ids = var.data_center_id == null ? [
    for d in data.hostinger_vps_data_centers.available[0].data_centers : d.id
    if var.region != null && strcontains(lower("${d.name} ${d.city} ${d.location} ${d.continent}"), lower(coalesce(var.region, "")))
  ] : []
  data_center_id = var.data_center_id != null ? var.data_center_id : (length(local.region_match_ids) == 1 ? local.region_match_ids[0] : null)
}

locals {
  # Map version-number => template id for PLAIN Debian OS templates only. The
  # name is start/end-anchored ("Debian 12", not "… on Debian" app/panel
  # templates), and the newest is chosen by parsed version, not by catalog id
  # (newest id tends to be the latest app template, not the OS).
  debian_os = var.template_id == null ? {
    for t in data.hostinger_vps_templates.available[0].templates :
    regex("^[Dd]ebian (\\d+)$", trimspace(t.name))[0] => t.id
    if can(regex("^[Dd]ebian \\d+$", trimspace(t.name)))
  } : {}
  debian_latest_id = length(local.debian_os) > 0 ? local.debian_os[tostring(max([for v in keys(local.debian_os) : tonumber(v)]...))] : null
  template_id      = var.template_id != null ? var.template_id : local.debian_latest_id
}

resource "hostinger_vps_ssh_key" "admin" {
  name = "${var.name}-admin"
  key  = var.ssh_public_key
}

resource "hostinger_vps" "this" {
  hostname       = var.name
  plan           = var.plan
  data_center_id = local.data_center_id
  template_id    = local.template_id
  ssh_key_ids    = [tonumber(hostinger_vps_ssh_key.admin.id)]

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [template_id, ssh_key_ids]

    precondition {
      condition     = local.template_id != null
      error_message = "no plain Debian template found in the Hostinger catalog; set template_id explicitly."
    }

    precondition {
      condition     = local.data_center_id != null
      error_message = "region '${coalesce(var.region, "<unset>")}' did not match exactly one Hostinger data center; refine region or set data_center_id explicitly."
    }
  }
}
