const SilentOptionFactory = artifacts.require("SilentOptionFactory")

module.exports = function(deployer) {
  deployer.deploy(SilentOptionFactory);
};
