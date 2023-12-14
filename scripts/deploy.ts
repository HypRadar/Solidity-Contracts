import { ethers } from "hardhat";

async function main() {
  const mintingFeeInBPS = "25"; // 0.25%
  const projectCreationFeeEther = ethers.parseEther("0.41"); // 410000000000000000 wei

  const repFactory = await ethers.deployContract("RepFactory", [mintingFeeInBPS, projectCreationFeeEther]);
  const repERC20 = await ethers.deployContract("RepERC20", []);

  await repFactory.waitForDeployment();
  await repERC20.waitForDeployment();

  console.log(
    `Rep Factory contract deployed to ${repFactory.target}`
  );
  console.log(
    `Rep ERC20 contract deployed to ${repERC20.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
