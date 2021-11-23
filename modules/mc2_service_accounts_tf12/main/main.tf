locals {
  all_service_accounts = flatten([for lm in var.additional_local_markets:[
      for subnet in var.tenant_sub_stages:[
          {
              id = "vf-${lower(lm)}-${var.program}-${subnet}-dp-${ subnet == "dev" || subnet == "qa" ? "ds" : "ops"}-ds"
              description = "${upper(lm)} Dataproc-${subnet} service account"
              roles = var.dataproc_roles
          }
      ]
  ]])

  additional_roles_flattend = length(var.additional_local_markets) != 0  ? flatten([
      for service_account in local.all_service_accounts : [
          for role in service_account.roles : {
              sa_email = "serviceAccount:${sa.email}"
              role = role
          }
      ]
  ]) : []

  custome_sa_id = length(var.additional_local_markets) != 0 ? flatten([
      for sa in google_service_account.service_accounts : [
          sa.id
      ]
  ]) : []
}

resource "google_service_account" "service_accounts" {
  count = length(local.all_service_accounts)
  project = var.project_name
  account_id = lookup(local.all_service_accounts[count.index],"id")
  display_name = lookup(local.all_service_accounts[count.index],"description")
}

resource "google_project_iam_member" "service_accounts_roles" {
  count = length(local.additional_roles_flattend)
  project = var.project_name
  member = lookup(local.additional_roles_flattend[count.index],"sa_email")
  role = lookup(local.additional_roles_flattend[count.index],"role")
  depends_on = [
    google_service_account.service_accounts
  ]
}

resource "google_service_account_iam_member" "composer-custom-sa-serviceAccountUser" {
  count = var.required_additional_sa_role ? length(local.custom_sa_id) : 0
  service_account_id =  element(local.custom_sa_id,count.index)
  role = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${var.composer_email}"
  depends_on = [
    google_service_account.service_accounts
  ]
}