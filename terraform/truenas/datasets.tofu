# Datasets below the two pools (the pools themselves are not managed). force_destroy
# stays false: the provider refuses to destroy or replace a dataset that holds
# data. Encryption is inherited from the pool unless a dataset says otherwise;
# keys are write-only and never read back. Skill `truenas-nas`.

resource "truenas_dataset" "storage_para" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "OFF"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/PARA"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_media" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "OFF"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/Media"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "pool_ssd_home_ops" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "OFF"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "pool_ssd/Home-Ops"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_software" {
  aclmode            = "RESTRICTED"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/software"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "pool_ssd_ai" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "OFF"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "pool_ssd/AI"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "pool_ssd_mgt_sklab_dev_netboot" {
  aclmode            = "RESTRICTED"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "pool_ssd/mgt.sklab.dev/netboot"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "pool_ssd_mgt_sklab_dev_vaultwarden" {
  aclmode            = "RESTRICTED"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "pool_ssd/mgt.sklab.dev/vaultwarden"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage_media" {
  aclmode            = "PASSTHROUGH"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage/media"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "pool_ssd_cedph_bk" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "OFF"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "pool_ssd/cedph_bk"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_app_data" {
  aclmode            = "INHERIT"
  acltype            = "posix"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/app-data"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage_incomming" {
  aclmode            = "PASSTHROUGH"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage/incomming"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  refreservation     = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "pool_ssd_restic" {
  aclmode            = "INHERIT"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "pool_ssd/Restic"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_shared" {
  aclmode            = "RESTRICTED"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/shared"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_para_0_inbox_1_photo_auto_import" {
  aclmode            = "RESTRICTED"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/PARA/0-Inbox/1-Photo-Auto-Import"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_documents" {
  aclmode            = "INHERIT"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/documents"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_para_4_archives" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "OFF"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/PARA/4-Archives"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "pool_ssd_home_ops_volsync" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "OFF"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "pool_ssd/Home-Ops/Volsync"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_para_2_areas_photos" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "OFF"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/PARA/2-Areas/Photos"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage_crypto" {
  aclmode            = "RESTRICTED"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage/crypto"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage_development" {
  aclmode            = "PASSTHROUGH"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = "Everything around Programming"
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage/development"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage_media_movies" {
  aclmode            = "PASSTHROUGH"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "SHA512"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage/media/Movies"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  refreservation     = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage_documents" {
  aclmode            = "PASSTHROUGH"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage/documents"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "pool_ssd_cluster_sklab_dev_proxmox_backup_server" {
  aclmode            = "RESTRICTED"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "pool_ssd/cluster.sklab.dev/proxmox-backup-server"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_app_data_gitea" {
  aclmode            = "INHERIT"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/app-data/gitea"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage_tia_project_server" {
  aclmode            = "INHERIT"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage/tia-project-server"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  refreservation     = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage" {
  aclmode            = "PASSTHROUGH"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_para_0_inbox_3_ebook_auto_import" {
  aclmode            = "RESTRICTED"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/PARA/0-Inbox/3-Ebook-Auto-Import"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_para_2_areas" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "OFF"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/PARA/2-Areas"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage_vmware" {
  aclmode            = "PASSTHROUGH"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = "Vmware Images / Backups"
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage/vmware"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  refreservation     = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_scripts" {
  aclmode            = "INHERIT"
  acltype            = "posix"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/scripts"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_work" {
  aclmode            = "RESTRICTED"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = "Everything Work Related"
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/work"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_photos" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/photos"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage_software" {
  aclmode            = "RESTRICTED"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage/software"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_para_0_inbox" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "OFF"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/PARA/0-Inbox"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "pool_ssd_miniio" {
  aclmode            = "INHERIT"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "pool_ssd/MiniIO"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_documents_scanner" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "OFF"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/documents/scanner"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "pool_ssd_mgt_sklab_dev" {
  aclmode            = "RESTRICTED"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "pool_ssd/mgt.sklab.dev"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "pool_ssd_cluster_sklab_dev" {
  aclmode            = "RESTRICTED"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "pool_ssd/cluster.sklab.dev"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup" {
  aclmode            = "PASSTHROUGH"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "lz4"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "HIDDEN"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_photos_db_backup" {
  aclmode            = "INHERIT"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/photos/db_backup"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_para_0_inbox_0_document_auto_import" {
  aclmode            = "RESTRICTED"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/PARA/0-Inbox/0-Document-Auto-Import"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_documents_training" {
  aclmode            = "RESTRICTED"
  acltype            = "nfsv4"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = true
  name               = "storage/documents/Training"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage_work" {
  aclmode            = "RESTRICTED"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = "Everything Work Related"
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage/work"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}


resource "truenas_dataset" "storage_pool_backup_storage_backup" {
  aclmode            = "PASSTHROUGH"
  acltype            = "inherit"
  atime              = "INHERIT"
  checksum           = "INHERIT"
  comments           = ""
  compression        = "inherit"
  copies             = 1
  dedup              = "INHERIT"
  encryption         = false
  exec               = "INHERIT"
  force_destroy      = false
  inherit_encryption = false
  name               = "storage/pool_backup/storage/backup"
  quota              = 0
  readonly           = "INHERIT"
  refquota           = 0
  reservation        = 0
  snapdir            = "INHERIT"
  sync               = "INHERIT"
  type               = "filesystem"
  volsize            = 0
}
