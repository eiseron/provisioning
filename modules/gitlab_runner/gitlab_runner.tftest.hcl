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
    condition     = hcloud_server.this.name == var.name
    error_message = "Server name must match var.name"
  }

  assert {
    condition     = hcloud_server.this.server_type == "cx33"
    error_message = "Default server_type must be cx33"
  }

  assert {
    condition     = hcloud_server.this.location == "nbg1"
    error_message = "Default location must be nbg1"
  }

  assert {
    condition     = hcloud_server.this.image == "debian-13"
    error_message = "Default image must be debian-13"
  }

  assert {
    condition     = hcloud_ssh_key.this.name == "${var.name}-admin"
    error_message = "SSH key name must be <name>-admin"
  }

  assert {
    condition     = gitlab_user_runner.this.runner_type == "group_type"
    error_message = "Runner type must be group_type"
  }

  assert {
    condition     = gitlab_user_runner.this.group_id == var.group_id
    error_message = "Runner group_id must match var.group_id"
  }

  assert {
    condition     = gitlab_user_runner.this.untagged == true
    error_message = "Runner must accept untagged jobs by default"
  }

  assert {
    condition     = gitlab_user_runner.this.maximum_timeout == 28800
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
    condition     = hcloud_server.this.server_type == "cx21"
    error_message = "server_type override must be applied"
  }

  assert {
    condition     = hcloud_server.this.location == "fsn1"
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
    condition     = toset(gitlab_user_runner.this.tag_list) == toset(["self-hosted", "prod"])
    error_message = "tag_list override must be applied"
  }

  assert {
    condition     = gitlab_user_runner.this.untagged == false
    error_message = "untagged override must be applied"
  }
}
