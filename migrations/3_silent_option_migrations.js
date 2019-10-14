const SilentOption = artifacts.require("SilentOption");
const SilentOptionFactory = artifacts.require("SilentOptionFactory")

module.exports = function(deployer) {
  deployer.deploy(SilentOption);
  deployer.deploy(SilentOptionFactory);
};
