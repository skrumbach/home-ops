# Local users and groups, without the built-in ones, `admin` and `tofu-read-only`.
# Group references are TrueNAS ids. Email, real name and password stay out of
# Git: full_name is a placeholder and all three are ignore_changes.

resource "truenas_user" "cluster_sklab_proxmox" {
  group                  = 119
  group_create           = true
  groups                 = []
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3005
  username               = "cluster-sklab-proxmox"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "cluster-sklab-proxmox"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_group" "photos_manage" {
  gid                    = 3006
  name                   = "photos_manage"
  smb                    = true
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = [76]
}


resource "truenas_group" "mgt_sklab" {
  gid                    = 3011
  name                   = "mgt-sklab"
  smb                    = false
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = []
}


resource "truenas_user" "immich_k8s" {
  group                  = 112
  group_create           = false
  groups                 = [116, 117]
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3003
  username               = "immich_k8s"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "immich_k8s"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_user" "media" {
  group                  = 115
  group_create           = true
  groups                 = []
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = true
  shell                  = "/usr/sbin/nologin"
  smb                    = false
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3002
  username               = "media"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "media"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_group" "media" {
  gid                    = 3000
  name                   = "media"
  smb                    = false
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = [72, 74]
}


resource "truenas_group" "documents_scanner" {
  gid                    = 3015
  name                   = "documents_scanner"
  smb                    = true
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = []
}


resource "truenas_group" "household" {
  gid                    = 3001
  name                   = "household"
  smb                    = true
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = [72]
}


resource "truenas_group" "minio" {
  gid                    = 3013
  name                   = "minio"
  smb                    = false
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = []
}


resource "truenas_group" "borg_backup" {
  gid                    = 3012
  name                   = "borg-backup"
  smb                    = false
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = []
}


resource "truenas_user" "unify_protect" {
  group                  = 121
  group_create           = false
  groups                 = [122]
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3007
  username               = "unify-protect"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "unify-protect"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_group" "ebook_manage" {
  gid                    = 3004
  name                   = "ebook_manage"
  smb                    = true
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = [72, 74]
}


resource "truenas_group" "ebook_read" {
  gid                    = 3003
  name                   = "ebook_read"
  smb                    = true
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = []
}


resource "truenas_user" "calibre_k8s" {
  group                  = 112
  group_create           = false
  groups                 = [115, 114]
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3001
  username               = "calibre_k8s"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "calibre_k8s"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_user" "borg_backup" {
  group                  = 124
  group_create           = true
  groups                 = [94]
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3009
  username               = "borg-backup"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "borg-backup"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_group" "unify" {
  gid                    = 3010
  name                   = "unify"
  smb                    = true
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = [81]
}


resource "truenas_user" "longhorn_k8s" {
  group                  = 118
  group_create           = true
  groups                 = [112]
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3004
  username               = "longhorn_k8s"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "longhorn_k8s"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_user" "aviator" {
  group                  = 41
  group_create           = false
  groups                 = [111, 114, 115, 126]
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3000
  username               = "aviator"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "aviator"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_user" "minio" {
  group                  = 125
  group_create           = true
  groups                 = [126]
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3010
  username               = "minio"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "minio"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_user" "proxmox_pbs" {
  group                  = 119
  group_create           = false
  groups                 = [119]
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3006
  username               = "proxmox-pbs"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "proxmox-pbs"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_group" "cluster_sklab_proxmox" {
  gid                    = 3008
  name                   = "cluster-sklab-proxmox"
  smb                    = false
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = []
}


resource "truenas_group" "home_ops" {
  gid                    = 2000
  name                   = "home-ops"
  smb                    = true
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = []
}


resource "truenas_user" "mgt_sklab" {
  group                  = 123
  group_create           = true
  groups                 = []
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3008
  username               = "mgt-sklab"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "mgt-sklab"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_user" "home_ops" {
  group                  = 129
  group_create           = true
  groups                 = []
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 2000
  username               = "home-ops"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "home-ops"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_group" "surveillance" {
  gid                    = 3009
  name                   = "surveillance"
  smb                    = true
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = []
}


resource "truenas_group" "longhorn_k8s" {
  gid                    = 3007
  name                   = "longhorn_k8s"
  smb                    = false
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = []
}


resource "truenas_user" "scanner" {
  group                  = 132
  group_create           = false
  groups                 = []
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3012
  username               = "scanner"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "scanner"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_user" "para" {
  group                  = 126
  group_create           = true
  groups                 = []
  home                   = "/var/empty"
  locked                 = false
  password_disabled      = false
  shell                  = "/usr/sbin/nologin"
  smb                    = true
  ssh_password_enabled   = false
  sshpubkey              = ""
  sudo_commands          = []
  sudo_commands_nopasswd = []
  uid                    = 3011
  username               = "para"
  webshare               = false

  # Placeholder: the real name lives only in TrueNAS (ignore_changes).
  full_name = "para"

  lifecycle {
    # Personal data and write-only secrets stay in TrueNAS only.
    ignore_changes = [email, full_name, password]
  }
}


resource "truenas_group" "photos_read" {
  gid                    = 3005
  name                   = "photos_read"
  smb                    = true
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = [76]
}


resource "truenas_group" "para" {
  gid                    = 3014
  name                   = "para"
  smb                    = false
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = [72, 84]
}


resource "truenas_group" "k8s" {
  gid                    = 3002
  name                   = "k8s"
  smb                    = true
  sudo_commands          = []
  sudo_commands_nopasswd = []
  users                  = [77]
}
