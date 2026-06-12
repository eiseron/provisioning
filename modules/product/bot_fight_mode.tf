resource "cloudflare_bot_management" "this" {
  zone_id    = cloudflare_zone.this.id
  fight_mode = var.bot_fight_mode_enabled
}
