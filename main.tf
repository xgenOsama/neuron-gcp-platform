module "mc2_bigquery_datasets_tf12" {
  source = "./modules/mc2_bigquery_datasets_tf12/main"
  compute_project = "grp-mc2compute-nonlive"
  compute_project_program = "mc2cp"
  add_permission = true
  enable_new_qlik_sa = ["es"]
  additional_access = [
      "gcp-vf-es-mc2-self-service-ds@vodafone.com > roles/bigquery.dataViewer > vfes_mc2_nonlive_es_lake_mc2_presentation_processed_s",
      "gcp-vf-es-mc2-self-service-ds@vodafone.com > roles/bigquery.dataViewer > vfes_mc2_nonlive_es_lake_mc2_presentation_processed_v"
  ]
  tenant = "es"
  location = "europe-west1-a"
  project_name = "lab-project-vodafone"
  environment = "es"
  program = "mc2"
  stage = "nonlive"
  additional_local_markets = ["al"]
  disable_qlik_accounts = []
  //region = "europe-west1"
}