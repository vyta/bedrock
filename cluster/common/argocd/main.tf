provider "null" {
    version = "~>2.0.0"
}
 
resource "null_resource" "deploy_kubediff" {
  count  = "${var.enable_argocd ? 1 : 0}"
  provisioner "local-exec" {
       command = "echo 'Need to use this var so terraform waits for kubeconfig ' ${var.kubeconfig_complete};KUBECONFIG=${var.output_directory}/${var.kubeconfig_filename} ${path.module}/deploy_argocd.sh -f '${var.argocd_repo_url}' -g '${var.gitops_ssh_url}' -k '${var.gitops_ssh_key}'"
  }
 
  triggers {
    enable_argocd  = "${var.enable_argocd}"
  }
 
}