const ForwardFactory = artifacts.require("ForwardFactory");

module.exports = function(deployer) {
  deployer.deploy(ForwardFactory);
};
