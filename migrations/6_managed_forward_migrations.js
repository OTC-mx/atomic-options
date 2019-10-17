const PortfolioFactory = artifacts.require("PortfolioFactory");
const ManagedForwardFactory = artifacts.require("ManagedForwardFactory");

module.exports = function(deployer) {
  deployer.deploy(PortfolioFactory);
  deployer.deploy(ManagedForwardFactory);
};
