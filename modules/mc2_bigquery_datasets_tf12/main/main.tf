locals {
  datasets_roles = [
      "roles/bigquert.dataEditor"
  ]
  subnets = var.stage == "live" ? ["proda","prodb"] : ["dev","qa","preprod"]

  # list of required datasets for tenant
  tenant_datasets = var.tenant != "grp" ? [
      "vf${var.tenant}_${var.program}_${var.stage}_${var.tenant}_lake_mc2_rawprepared_s",
      "vf${var.tenant}_${var.program}_${var.stage}_${var.tenant}_lake_mc2_rawprepared_v",
      "vf${var.tenant}_${var.program}_${var.stage}_${var.tenant}_lake_mc2_processed_s",
      "vf${var.tenant}_${var.program}_${var.stage}_${var.tenant}_lake_mc2_processed_v",
      "vf${var.tenant}_${var.program}_${var.stage}_${var.tenant}_lake_mc2_presentation_processed_s",
      "vf${var.tenant}_${var.program}_${var.stage}_${var.tenant}_lake_mc2_presentation_processed_v",
      "vf${var.tenant}_${var.program}_${var.stage}_${var.tenant}_model_mc2_aa_processed_s",
      "vf${var.tenant}_${var.program}_${var.stage}_${var.tenant}_model_mc2_aa_processed_v",
      "vf${var.tenant}_${var.program}_${var.stage}_${var.tenant}_model_mc2_aa_features_s",
  ] : []

  # toset pass a list value to toset to convert it to a set , which will remove any duplicated elements and discard the ordering of the elements .
  # flatten: takes a list and replace any elements that are lists  flatten([["a", "b"], [], ["c"]]) >> ["a", "b", "c"]
  all_datasets = toset(concat(flatten([for lm in var.additional_local_markets : [
      "vf${var.tenant}_${var.program}_${var.stage}_${lower(lm)}_lake_mc2_rawprepared_s",
      "vf${var.tenant}_${var.program}_${var.stage}_${lower(lm)}_lake_mc2_rawprepared_v",
      "vf${var.tenant}_${var.program}_${var.stage}_${lower(lm)}_lake_mc2_processed_s",
      "vf${var.tenant}_${var.program}_${var.stage}_${lower(lm)}_lake_mc2_processed_v",
      "vf${var.tenant}_${var.program}_${var.stage}_${lower(lm)}_lake_mc2_presentation_processed_s",
      "vf${var.tenant}_${var.program}_${var.stage}_${lower(lm)}_lake_mc2_presentation_processed_v",
      "vf${var.tenant}_${var.program}_${var.stage}_${lower(lm)}_model_mc2_aa_processed_s",
      "vf${var.tenant}_${var.program}_${var.stage}_${lower(lm)}_model_mc2_aa_processed_v",
      "vf${var.tenant}_${var.program}_${var.stage}_${lower(lm)}_model_mc2_aa_features_s",
  ]]),local.tenant_datasets))
  # group@company.com > roles/bigquery.dataViewer > vfes_mc2_nonlive_es_lake_mc2_presentation_processed_s
  additional_groups_access = {for dataset in local.all_datasets :
    dataset => length(var.additional_access) != 0 ? flatten([
        for access in var.additional_access : {
            member = regexall("(.*) > .* > .*",access)[0][0]
            role = regexall(".* > (.*) > .*",access)[0][0]
        } if length(regexall("@company.com",regexall("(.*) > .* > .*",access)[0][0])) == 1 && dataset == regexall(".* > .* > (.*)",access)[0][0]
    ]) : []
  }

  additional_users_access = {for dataset in local.all_datasets :
    dataset => length(var.additional_access) != 0 ? flatten([
        for access in var.additional_access : {
            member = regexall("(.*) > .* > .*",access)[0][0]
            role = regexall(".* > (.*) > .*",access)[0][0]
        } if length(regexall("@company.com",regexall("(.*) > .* > .*",access)[0][0])) != 1 && dataset == regexall(".* > .* > (.*)",access)[0][0]
    ]) : []
  }

  # permissions to service account 
  localmarkets = var.tenant == "grp" || var.tenant == "mc2dev" ? var.additional_local_markets : concat(var.additional_local_markets,[var.tenant])
  
  dataset_service_accounts = flatten([for lm in local.localmarkets : [
      for subnet in local.subnets : [
          "vf-${lower(lm)}-${var.compute_project_program}-${subnet}-dp-${subnet == "preprod" ? "ops" : "ds"}-sa@vf-${var.compute_project}.iam.gserviceaccount.com"
      ]
  ]])

  dataset_sa_role_map = {
    for dataset in local.all_datasets : dataset => var.add_permission ? 
    {for sa in local.dataset_service_accounts : sa => local.datasets_roles[0] if split("_",dataset)[3] == split("-",sa)[1]}
    : {}
  }
}

resource "google_bigquery_dataset" "tenant_dataset" {
  for_each = local.all_datasets
  dataset_id = each.value
  location = var.location
  project = var.project_name

  #++++++++++++++++++++++++++++++++++ needs owner and privileges or can't create dataset +++++++++++++++++++++++++++++++++++#
  access {
    role = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role = "READER"
    special_group = "projectReaders"
  }

  access {
    role = "WRITER"
    special_group = "projectWriters"
  }
  #++++++++++++++++++++++++++++++++++++++++++++++++++++ Access specific to the aa datasets +++++++++++++++++++++++++++++++++++++++#
  dynamic "access"{
      for_each = contains(split("_",each.value),"aa") == true ? ["1"] : []
      content {
          role = "roles/bigquery.dataEditor"
          group_by_email = "gcp-vf-${var.tenant}-${var.program}-ds-user@vodafone.com"
      }
  }

    dynamic "access"{
      for_each = contains(split("_",each.value),"aa") == true ? ["1"] : []
      content {
          role = "roles/bigquery.dataEditor"
          group_by_email = "gcp-vf-${var.tenant}-${var.program}-de-user@vodafone.com"
      }
  }
  #++++++++++++++++++++++++++++++++++++++++++++++++++++ Qlik FAs functional accounts +++++++++++++++++++++++++++++++++++++++#
  dynamic "access" {
      for_each = contains(var.disable_qlik_accounts, split("_",each.value)[3]) != true && replace(each.value,"/(?:.*)(lake_mc2_presentation_processed_s)(?:.*)/","$1") == "lake_mc2_presentation_processed_s" ? ["1"] : []
      content{
          role = "roles/bigquery.dataViewer"
          user_by_email = split("_",each.value)[3] == "ro" || split("_",each.value)[3] == "al" ? "vfgroupsvc-${split("_",each.value)[3]}bgd@vodafone.com" : "vfgroupsvc_${split("_",each.value)[3]}bgd@vodafone.com"
      }
  }
  dynamic "access" {
      for_each = contains(var.disable_qlik_accounts, split("_",each.value)[3]) != true && replace(each.value,"/(?:.*)(lake_mc2_aa_processed_s)(?:.*)/","$1") == "lake_mc2_aa_processed_s" ? ["1"] : []
      content{
          role = "roles/bigquery.dataViewer"
          user_by_email = split("_",each.value)[3] == "ro" || split("_",each.value)[3] == "al" ? "vfgroupsvc-${split("_",each.value)[3]}bgd@vodafone.com" : "vfgroupsvc_${split("_",each.value)[3]}bgd@vodafone.com"
      }
  }

  #++++++++++++++++++++++++++++++++++++++++++++++++++++ Qlik SAs service accounts +++++++++++++++++++++++++++++++++++++++#
  dynamic "access" {
      for_each = contains(var.enable_new_qlik_sa, split("_",each.value)[3]) == true && replace(each.value,"/(?:.*)(lake_mc2_presentation_processed_s)(?:.*)/","$1") == "lake_mc2_presentation_processed_s" ? ["1"] : []
      content{
          role = "roles/bigquery.dataViewer"
          user_by_email = "bq-${split("_",each.value)[3]}-mc2@vf-grp-ngbi-pprd-svcs-01-iam.gserviceaccount.com" 
      }
  }
  dynamic "access" {
      for_each = contains(var.enable_new_qlik_sa, split("_",each.value)[3]) == true && replace(each.value,"/(?:.*)(lake_mc2_aa_processed_s)(?:.*)/","$1") == "lake_mc2_aa_processed_s" ? ["1"] : []
      content{
          role = "roles/bigquery.dataViewer"
          user_by_email = "bq-${split("_",each.value)[3]}-mc2@vf-grp-ngbi-pprd-svcs-01-iam.gserviceaccount.com" 
      }
  }
  # ++++++++++++++++++++++++++++ Replacment of add permission module +++++++++++++++++++++++++++++++ #
  dynamic "access" {
      for_each = lookup(local.dataset_sa_role_map,each.value)
      content {
          role = access.value
          user_by_email = access.key
      }
  }
  #+++++++++++++++++++++++++++ additional access +++++++++++++++++++++++++++++++++#
  dynamic "access"{
      for_each = lookup(local.additional_groups_access,each.value)
      content {
          group_by_email = access.value.member
          role = access.value.role
      }
  }
  dynamic "access"{
      for_each = lookup(local.additional_users_access,each.value)
      content {
          user_by_email = access.value.member
          role = access.value.role
      }
  }
}