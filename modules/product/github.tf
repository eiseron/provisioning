module "github_mirror" {
  source   = "../github_repository"
  for_each = local.mirror_repositories

  name        = each.key
  description = each.value.description
  topics      = each.value.topics
}
