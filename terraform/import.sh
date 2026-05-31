#!/usr/bin/env bash
set -euo pipefail

# Terraform import commands for existing Yandex Cloud resources.
# Run from the terraform/ directory: cd terraform && bash import.sh

SA_ID="aje73960eje3ufiv2bto"
FOLDER_ID="b1g7scs6lgrf9ijk4dff"
LOCKBOX_ID="e6qknf8t938ldnctsl3j"
CONTAINER_ID="bbaph33gp6gjmcq62tqi"

terraform import yandex_iam_service_account.youtwoy_sa "$SA_ID"

terraform import yandex_resourcemanager_folder_iam_member.sa_storage_editor \
  "${FOLDER_ID}/storage.editor/serviceAccount:${SA_ID}"

terraform import yandex_resourcemanager_folder_iam_member.sa_registry_puller \
  "${FOLDER_ID}/container-registry.images.puller/serviceAccount:${SA_ID}"

terraform import yandex_lockbox_secret_iam_member.sa_payload_viewer \
  "${LOCKBOX_ID} lockbox.payloadViewer serviceAccount:${SA_ID}"

terraform import yandex_serverless_container.bot "$CONTAINER_ID"

terraform import yandex_serverless_container_iam_binding.public_invoke \
  "${CONTAINER_ID} serverless-containers.containerInvoker"

echo "All resources imported successfully"
