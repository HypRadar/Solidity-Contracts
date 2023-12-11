import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("HypRepProtocol", function () {
  async function deployRepFixtures() {
    const [owner, community, alice, bob, carol, david, erin] =
      await ethers.getSigners();
    const mintingFeeInBPS = "25"; // 0.25%
    const projectCreationFeeEther = ethers.parseEther("0.41");

    const RepFactory = await ethers.getContractFactory("RepFactory");
    const repFactory = await RepFactory.deploy(
      mintingFeeInBPS,
      projectCreationFeeEther
    );

    return { repFactory, owner, community, alice, bob, carol, david, erin, projectCreationFeeEther };
  }

  describe("Cases for Rep Creation and trading", function () {
    it("should fail when creating rep without sending ETH", async function () {
      const { repFactory, community, projectCreationFeeEther } = await loadFixture(deployRepFixtures);

        await expect(repFactory
          .connect(community)
          .createRep("FAT-REP", community.address, 1000)).to.be.rejectedWith("Incorrect rep creation fee");

        await expect(repFactory
          .connect(community)
          .createRep("FAT-REP", community.address, 1000, { value: '100000000000'})).to.be.rejectedWith("Incorrect rep creation fee");
    });

    it("should fail with incorrect arguments", async function () {
      const { repFactory, community, projectCreationFeeEther } = await loadFixture(deployRepFixtures);

        await expect(repFactory
          .connect(community)
          .createRep("FAT-REP", community.address, 100000)).to.be.rejectedWith("Incorrect royalty set");

        await repFactory
          .connect(community)
          .createRep("FAT-REP", community.address, 1000, { value: projectCreationFeeEther});
        await expect(repFactory
          .connect(community)
          .createRep("FAT-REP", community.address, 1000, { value: projectCreationFeeEther})).to.be.rejectedWith("You have created a REP with this Ticker before");
    });

    
  });
});
