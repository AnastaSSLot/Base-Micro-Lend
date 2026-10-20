const hre = require("hardhat");
async function main() {
  const HubData = await hre.ethers.getContractFactory("OmniMicroLendHub");
  const lendingHub = await HubData.deploy();
  await lendingHub.deployed();
  console.log("-> P2P Lending Engine active at:", lendingHub.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
