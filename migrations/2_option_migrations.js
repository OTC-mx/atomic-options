const Option = artifacts.require("option");
const OptionFactory = artifacts.require("option_factory")

module.exports = function(deployer) {
  deployer.deploy(Option);
  deployer.deploy(OptionFactory);
};
