import { ethers } from "hardhat";

async function main() {
  const kleosFactory = await ethers.deployContract("KleosFactory", []);

  await kleosFactory.waitForDeployment();

  console.log(
    `Kleos Factory contract deployed to ${kleosFactory.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
