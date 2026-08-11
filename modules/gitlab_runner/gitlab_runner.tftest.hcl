mock_provider "hcloud" {}
mock_provider "gitlab" {}

variables {
  name           = "test-runner"
  group_id       = 12345678
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITestKeyForValidation test@example.com"
}

run "variables_are_passed_through" {
  command = plan

  assert {
    condition     = hcloud_server.this[0].name == var.name
    error_message = "Server name must match var.name"
  }

  assert {
    condition     = hcloud_server.this[0].server_type == "cx33"
    error_message = "Default server_type must be cx33"
  }

  assert {
    condition     = hcloud_server.this[0].location == "nbg1"
    error_message = "Default location must be nbg1"
  }

  assert {
    condition     = hcloud_server.this[0].image == "debian-13"
    error_message = "Default image must be debian-13"
  }

  assert {
    condition     = hcloud_ssh_key.this[0].name == "${var.name}-admin"
    error_message = "SSH key name must be <name>-admin"
  }

  assert {
    condition     = gitlab_user_runner.this[0].runner_type == "group_type"
    error_message = "Runner type must be group_type"
  }

  assert {
    condition     = gitlab_user_runner.this[0].group_id == var.group_id
    error_message = "Runner group_id must match var.group_id"
  }

  assert {
    condition     = gitlab_user_runner.this[0].untagged == true
    error_message = "Runner must accept untagged jobs by default"
  }

  assert {
    condition     = gitlab_user_runner.this[0].maximum_timeout == 28800
    error_message = "Default maximum_timeout must be 28800"
  }
}

run "custom_server_type_overrides_default" {
  command = plan

  variables {
    server_type = "cx21"
    location    = "fsn1"
  }

  assert {
    condition     = hcloud_server.this[0].server_type == "cx21"
    error_message = "server_type override must be applied"
  }

  assert {
    condition     = hcloud_server.this[0].location == "fsn1"
    error_message = "location override must be applied"
  }
}

run "custom_tags_override_default" {
  command = plan

  variables {
    tag_list = ["self-hosted", "prod"]
    untagged = false
  }

  assert {
    condition     = toset(gitlab_user_runner.this[0].tag_list) == toset(["self-hosted", "prod"])
    error_message = "tag_list override must be applied"
  }

  assert {
    condition     = gitlab_user_runner.this[0].untagged == false
    error_message = "untagged override must be applied"
  }
}

run "runner_exists_by_default" {
  command = plan

  assert {
    condition     = length(hcloud_server.this) == 1
    error_message = "The runner VM must exist unless decommission is set"
  }

  assert {
    condition     = length(hcloud_ssh_key.this) == 1
    error_message = "The Hetzner SSH key must exist unless decommission is set"
  }

  assert {
    condition     = length(gitlab_user_runner.this) == 1
    error_message = "The GitLab runner registration must exist unless decommission is set"
  }
}

run "decommission_tears_down_every_billable_resource" {
  command = plan

  variables {
    decommission = true
  }

  assert {
    condition     = length(hcloud_server.this) == 0
    error_message = "decommission must tear down the runner VM, which is the recurring cost"
  }

  assert {
    condition     = length(hcloud_ssh_key.this) == 0
    error_message = "decommission must tear down the Hetzner SSH key"
  }

  assert {
    condition     = length(gitlab_user_runner.this) == 0
    error_message = "decommission must tear down the GitLab runner registration so no dangling runner stays in the group"
  }
}

run "decommission_nulls_the_wiring_outputs" {
  command = plan

  variables {
    decommission = true
  }

  assert {
    condition     = output.runner_ipv4 == null
    error_message = "runner_ipv4 must be null when decommissioned so callers can gate on it instead of reading a stale address"
  }

  assert {
    condition     = output.ssh_key_id == null
    error_message = "ssh_key_id must be null when decommissioned"
  }
}
