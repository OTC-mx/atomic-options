const SilentOption = artifacts.require("silent_option");
const SilentOptionFactory = artifacts.require("silent_option_factory")

module.exports = function(deployer) {
  deployer.deploy(SilentOption);
  deployer.deploy(SilentOptionFactory);
};
