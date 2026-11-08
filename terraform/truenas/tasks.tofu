# Periodic snapshot, scrub and cron tasks. Skill `truenas-nas`.

resource "truenas_periodic_snapshot_task" "storage_photos" {
  allow_empty    = true
  dataset        = "storage/photos"
  enabled        = true
  exclude        = []
  lifetime_unit  = "WEEK"
  lifetime_value = 2
  naming_schema  = "auto-%Y-%m-%d_%H-%M"
  recursive      = true
  schedule = {
    begin  = "00:00"
    dom    = "*"
    dow    = "*"
    end    = "23:59"
    hour   = "5"
    minute = "0"
    month  = "*"
  }
}


resource "truenas_scrub_task" "storage" {
  description = ""
  enabled     = true
  pool        = 4
  schedule = {
    dom    = "*"
    dow    = "7"
    hour   = "00"
    minute = "00"
    month  = "*"
  }
  threshold = 35
}


resource "truenas_scrub_task" "pool_ssd" {
  description = ""
  enabled     = true
  pool        = 5
  schedule = {
    dom    = "*"
    dow    = "7"
    hour   = "00"
    minute = "00"
    month  = "*"
  }
  threshold = 35
}


resource "truenas_cronjob" "s_m_a_r_t_test_smart" {
  command     = "midclt call disk.smart_test SHORT '[\"*\"]'"
  description = "S.M.A.R.T. Test: Smart"
  enabled     = true
  schedule = {
    dom    = "*"
    dow    = "*"
    hour   = "0"
    minute = "00"
    month  = "*"
  }
  stderr = true
  stdout = true
  user   = "root"
}
