const CallOption = artifacts.require("call_option");
const OptionFactory = artifacts.require("option_factory")

module.exports = function(deployer) {
  deployer.deploy(CallOption);
  deployer.deploy(OptionFactory);
};
