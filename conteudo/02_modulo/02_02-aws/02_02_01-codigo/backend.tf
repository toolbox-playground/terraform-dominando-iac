terraform {

  backend "local" {
    path = "./terraform-g-run.tfstate"
  }

}