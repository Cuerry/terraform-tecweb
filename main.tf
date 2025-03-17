module "network" {
  source        = "./modules/network"
}

module "compute_engine" {
  source = "./modules/compute_engine"
}