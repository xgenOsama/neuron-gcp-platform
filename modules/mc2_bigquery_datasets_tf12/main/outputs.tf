output "all_datasets" {
  value = local.all_datasets
}

output "datasets_details" {
  value = {for key,dataset in google_bigquery_dataset.tenant_dataset : key => dataset}
}