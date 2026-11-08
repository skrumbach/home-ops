# Adoption of the live TrueNAS objects (dataset path or numeric id). Inert once in
# state; kept so a lost state reattaches. Skill `truenas-nas`.

import {
  to = truenas_dataset.pool_ssd_mgt_sklab_dev
  id = "pool_ssd/mgt.sklab.dev"
}

import {
  to = truenas_dataset.pool_ssd_mgt_sklab_dev_vaultwarden
  id = "pool_ssd/mgt.sklab.dev/vaultwarden"
}

import {
  to = truenas_dataset.pool_ssd_mgt_sklab_dev_netboot
  id = "pool_ssd/mgt.sklab.dev/netboot"
}

import {
  to = truenas_dataset.pool_ssd_restic
  id = "pool_ssd/Restic"
}

import {
  to = truenas_dataset.pool_ssd_cluster_sklab_dev
  id = "pool_ssd/cluster.sklab.dev"
}

import {
  to = truenas_dataset.pool_ssd_cluster_sklab_dev_proxmox_backup_server
  id = "pool_ssd/cluster.sklab.dev/proxmox-backup-server"
}

import {
  to = truenas_dataset.pool_ssd_ai
  id = "pool_ssd/AI"
}

import {
  to = truenas_dataset.pool_ssd_cedph_bk
  id = "pool_ssd/cedph_bk"
}

import {
  to = truenas_dataset.pool_ssd_home_ops
  id = "pool_ssd/Home-Ops"
}

import {
  to = truenas_dataset.pool_ssd_home_ops_volsync
  id = "pool_ssd/Home-Ops/Volsync"
}

import {
  to = truenas_dataset.pool_ssd_miniio
  id = "pool_ssd/MiniIO"
}

import {
  to = truenas_dataset.storage_software
  id = "storage/software"
}

import {
  to = truenas_dataset.storage_para
  id = "storage/PARA"
}

import {
  to = truenas_dataset.storage_para_4_archives
  id = "storage/PARA/4-Archives"
}

import {
  to = truenas_dataset.storage_para_2_areas
  id = "storage/PARA/2-Areas"
}

import {
  to = truenas_dataset.storage_para_2_areas_photos
  id = "storage/PARA/2-Areas/Photos"
}

import {
  to = truenas_dataset.storage_para_0_inbox
  id = "storage/PARA/0-Inbox"
}

import {
  to = truenas_dataset.storage_para_0_inbox_3_ebook_auto_import
  id = "storage/PARA/0-Inbox/3-Ebook-Auto-Import"
}

import {
  to = truenas_dataset.storage_para_0_inbox_1_photo_auto_import
  id = "storage/PARA/0-Inbox/1-Photo-Auto-Import"
}

import {
  to = truenas_dataset.storage_para_0_inbox_0_document_auto_import
  id = "storage/PARA/0-Inbox/0-Document-Auto-Import"
}

import {
  to = truenas_dataset.storage_shared
  id = "storage/shared"
}

import {
  to = truenas_dataset.storage_pool_backup
  id = "storage/pool_backup"
}

import {
  to = truenas_dataset.storage_pool_backup_app_data
  id = "storage/pool_backup/app-data"
}

import {
  to = truenas_dataset.storage_pool_backup_app_data_gitea
  id = "storage/pool_backup/app-data/gitea"
}

import {
  to = truenas_dataset.storage_pool_backup_storage
  id = "storage/pool_backup/storage"
}

import {
  to = truenas_dataset.storage_pool_backup_storage_software
  id = "storage/pool_backup/storage/software"
}

import {
  to = truenas_dataset.storage_pool_backup_storage_documents
  id = "storage/pool_backup/storage/documents"
}

import {
  to = truenas_dataset.storage_pool_backup_storage_work
  id = "storage/pool_backup/storage/work"
}

import {
  to = truenas_dataset.storage_pool_backup_storage_crypto
  id = "storage/pool_backup/storage/crypto"
}

import {
  to = truenas_dataset.storage_pool_backup_storage_vmware
  id = "storage/pool_backup/storage/vmware"
}

import {
  to = truenas_dataset.storage_pool_backup_storage_development
  id = "storage/pool_backup/storage/development"
}

import {
  to = truenas_dataset.storage_pool_backup_storage_tia_project_server
  id = "storage/pool_backup/storage/tia-project-server"
}

import {
  to = truenas_dataset.storage_pool_backup_storage_media
  id = "storage/pool_backup/storage/media"
}

import {
  to = truenas_dataset.storage_pool_backup_storage_media_movies
  id = "storage/pool_backup/storage/media/Movies"
}

import {
  to = truenas_dataset.storage_pool_backup_storage_backup
  id = "storage/pool_backup/storage/backup"
}

import {
  to = truenas_dataset.storage_pool_backup_storage_incomming
  id = "storage/pool_backup/storage/incomming"
}

import {
  to = truenas_dataset.storage_pool_backup_scripts
  id = "storage/pool_backup/scripts"
}

import {
  to = truenas_dataset.storage_photos
  id = "storage/photos"
}

import {
  to = truenas_dataset.storage_photos_db_backup
  id = "storage/photos/db_backup"
}

import {
  to = truenas_dataset.storage_media
  id = "storage/Media"
}

import {
  to = truenas_dataset.storage_documents
  id = "storage/documents"
}

import {
  to = truenas_dataset.storage_documents_scanner
  id = "storage/documents/scanner"
}

import {
  to = truenas_dataset.storage_documents_training
  id = "storage/documents/Training"
}

import {
  to = truenas_dataset.storage_work
  id = "storage/work"
}

import {
  to = truenas_smb_share.photos
  id = "15"
}

import {
  to = truenas_smb_share.work_new
  id = "19"
}

import {
  to = truenas_smb_share.proxmox_backup_server
  id = "24"
}

import {
  to = truenas_smb_share.netboot_mgt
  id = "27"
}

import {
  to = truenas_smb_share.vaultwarden_mgt
  id = "28"
}

import {
  to = truenas_smb_share.para
  id = "32"
}

import {
  to = truenas_smb_share.software
  id = "33"
}

import {
  to = truenas_smb_share.cedph_bk
  id = "34"
}

import {
  to = truenas_smb_share.home_ops
  id = "35"
}

import {
  to = truenas_smb_share.volsync
  id = "36"
}

import {
  to = truenas_smb_share.scanner
  id = "40"
}

import {
  to = truenas_smb_share.media
  id = "41"
}

import {
  to = truenas_smb_share.training
  id = "42"
}

import {
  to = truenas_smb_share.storage
  id = "43"
}

import {
  to = truenas_smb_share.shared
  id = "44"
}

import {
  to = truenas_smb_share.andrews
  id = "45"
}

import {
  to = truenas_smb_share.ai
  id = "46"
}

import {
  to = truenas_nfs_share.r_0_document_auto_import
  id = "20"
}

import {
  to = truenas_nfs_share.cedph_bk
  id = "22"
}

import {
  to = truenas_nfs_share.home_ops
  id = "23"
}

import {
  to = truenas_nfs_share.volsync
  id = "24"
}

import {
  to = truenas_nfs_share.media
  id = "27"
}

import {
  to = truenas_nfs_share.scanner
  id = "31"
}

import {
  to = truenas_nfs_share.ai
  id = "32"
}

import {
  to = truenas_user.aviator
  id = "72"
}

import {
  to = truenas_user.calibre_k8s
  id = "74"
}

import {
  to = truenas_user.media
  id = "75"
}

import {
  to = truenas_user.immich_k8s
  id = "76"
}

import {
  to = truenas_user.longhorn_k8s
  id = "77"
}

import {
  to = truenas_user.cluster_sklab_proxmox
  id = "78"
}

import {
  to = truenas_user.proxmox_pbs
  id = "79"
}

import {
  to = truenas_user.unify_protect
  id = "81"
}

import {
  to = truenas_user.mgt_sklab
  id = "82"
}

import {
  to = truenas_user.borg_backup
  id = "83"
}

import {
  to = truenas_user.minio
  id = "84"
}

import {
  to = truenas_user.para
  id = "85"
}

import {
  to = truenas_user.home_ops
  id = "86"
}

import {
  to = truenas_user.scanner
  id = "88"
}

import {
  to = truenas_group.household
  id = "111"
}

import {
  to = truenas_group.k8s
  id = "112"
}

import {
  to = truenas_group.ebook_read
  id = "113"
}

import {
  to = truenas_group.ebook_manage
  id = "114"
}

import {
  to = truenas_group.media
  id = "115"
}

import {
  to = truenas_group.photos_read
  id = "116"
}

import {
  to = truenas_group.photos_manage
  id = "117"
}

import {
  to = truenas_group.longhorn_k8s
  id = "118"
}

import {
  to = truenas_group.cluster_sklab_proxmox
  id = "119"
}

import {
  to = truenas_group.surveillance
  id = "121"
}

import {
  to = truenas_group.unify
  id = "122"
}

import {
  to = truenas_group.mgt_sklab
  id = "123"
}

import {
  to = truenas_group.borg_backup
  id = "124"
}

import {
  to = truenas_group.minio
  id = "125"
}

import {
  to = truenas_group.para
  id = "126"
}

import {
  to = truenas_group.home_ops
  id = "129"
}

import {
  to = truenas_group.documents_scanner
  id = "132"
}

import {
  to = truenas_periodic_snapshot_task.storage_photos
  id = "4"
}

import {
  to = truenas_scrub_task.storage
  id = "4"
}

import {
  to = truenas_scrub_task.pool_ssd
  id = "5"
}

import {
  to = truenas_cronjob.s_m_a_r_t_test_smart
  id = "1"
}
