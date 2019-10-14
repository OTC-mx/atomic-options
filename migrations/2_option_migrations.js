const Option = artifacts.require("Option");
const OptionFactory = artifacts.require("OptionFactory")

module.exports = function(deployer) {
  deployer.deploy(StandardOption);
  deployer.deploy(OptionFactory);
};
