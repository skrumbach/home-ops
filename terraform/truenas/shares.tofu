# The cluster mounts only the `media` NFS share (/mnt/storage/Media): plex, sonarr, radarr, lidarr,
# bazarr, tdarr, shelfmark, calibre-web-automated. Changing or deleting it takes those apps down.

resource "truenas_smb_share" "netboot_mgt" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "netboot-mgt"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/pool_ssd/mgt.sklab.dev/netboot"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "photos" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "photos"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/storage/photos"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "media" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "Media"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/storage/Media"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "ai" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "AI"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/pool_ssd/AI"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_nfs_share" "scanner" {
  comment          = ""
  enabled          = true
  expose_snapshots = false
  hosts            = []
  mapall_group     = ""
  mapall_user      = ""
  maproot_group    = ""
  maproot_user     = ""
  networks         = []
  path             = "/mnt/storage/documents/scanner"
  ro               = false
  security         = []
}


resource "truenas_nfs_share" "volsync" {
  comment          = ""
  enabled          = true
  expose_snapshots = false
  hosts            = []
  mapall_group     = ""
  mapall_user      = ""
  maproot_group    = ""
  maproot_user     = ""
  networks         = ["10.10.10.0/24"]
  path             = "/mnt/pool_ssd/Home-Ops/Volsync"
  ro               = false
  security         = []
}


resource "truenas_nfs_share" "cedph_bk" {
  comment          = ""
  enabled          = true
  expose_snapshots = false
  hosts            = []
  mapall_group     = ""
  mapall_user      = ""
  maproot_group    = ""
  maproot_user     = ""
  networks         = []
  path             = "/mnt/pool_ssd/cedph_bk"
  ro               = false
  security         = []
}


resource "truenas_smb_share" "cedph_bk" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "cedph_bk"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/pool_ssd/cedph_bk"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "shared" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "Shared"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/storage/shared"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_nfs_share" "media" {
  comment          = ""
  enabled          = true
  expose_snapshots = false
  hosts            = []
  mapall_group     = ""
  mapall_user      = ""
  maproot_group    = ""
  maproot_user     = ""
  networks         = []
  path             = "/mnt/storage/Media"
  ro               = false
  security         = []
}


resource "truenas_nfs_share" "r_0_document_auto_import" {
  comment          = ""
  enabled          = true
  expose_snapshots = false
  hosts            = []
  mapall_group     = ""
  mapall_user      = ""
  maproot_group    = ""
  maproot_user     = ""
  networks         = ["10.10.10.0/24"]
  path             = "/mnt/storage/PARA/0-Inbox/0-Document-Auto-Import"
  ro               = false
  security         = []
}


resource "truenas_smb_share" "andrews" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "andrews"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "EXTERNAL:100.122.243.81\\Steam"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "volsync" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "Volsync"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/pool_ssd/Home-Ops/Volsync"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "training" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "Training"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/storage/documents/Training"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "software" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "software"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/storage/software"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "storage" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "storage"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/storage/pool_backup/storage"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "work_new" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "work_new"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/storage/work"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "para" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "PARA"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/storage/PARA"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "vaultwarden_mgt" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "vaultwarden-mgt"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/pool_ssd/mgt.sklab.dev/vaultwarden"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "home_ops" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "Home-Ops"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/pool_ssd/Home-Ops"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "scanner" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "scanner"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/storage/documents/scanner"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_smb_share" "proxmox_backup_server" {
  abe = false
  audit = {
    enable      = false
    ignore_list = []
    watch_list  = []
  }
  browsable = true
  comment   = ""
  enabled   = true
  name      = "proxmox-backup-server"
  options = {
    aapl_name_mangling = false
    hostsallow         = []
    hostsdeny          = []
  }
  path    = "/mnt/pool_ssd/cluster.sklab.dev/proxmox-backup-server"
  purpose = "DEFAULT_SHARE"
  ro      = false
}


resource "truenas_nfs_share" "ai" {
  comment          = ""
  enabled          = true
  expose_snapshots = false
  hosts            = []
  mapall_group     = ""
  mapall_user      = ""
  maproot_group    = ""
  maproot_user     = ""
  networks         = []
  path             = "/mnt/pool_ssd/AI"
  ro               = false
  security         = []
}


resource "truenas_nfs_share" "home_ops" {
  comment          = ""
  enabled          = true
  expose_snapshots = false
  hosts            = []
  mapall_group     = ""
  mapall_user      = ""
  maproot_group    = ""
  maproot_user     = ""
  networks         = ["10.10.10.0/24"]
  path             = "/mnt/pool_ssd/Home-Ops"
  ro               = false
  security         = []
}
