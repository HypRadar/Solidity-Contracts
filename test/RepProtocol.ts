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

    it("Project creates token and tokens get traded", async function () {
      let receipt;
      let tx;
      const deadline = ((await time.latest()) + 100).toString();
      const { repFactory, owner, community, alice, bob, carol, david, erin, projectCreationFeeEther } =
        await loadFixture(deployRepFixtures);

      const factory = await repFactory
        .connect(community)
        .createRep("FAT-REP", community.address, 1000, { value: projectCreationFeeEther});

      const repERC20Address = await repFactory.getRepAddress(
        "FAT-REP",
        community.address
      );

      const repERC20 = await ethers.getContractAt("RepERC20", repERC20Address);

      expect(String(await repERC20.totalSupply())).to.equal(ethers.parseEther("0").toString());
      expect(String(await repERC20.projectRoyaltyInBPS())).to.equal('1000');

      await expect(repERC20.connect(alice).changeProjectAddress(alice.address)).to.be.rejectedWith("RepERC20: Incorrect privilege")
      tx = await repERC20.connect(community).changeProjectAddress(bob.address);
      receipt = await tx.wait();

      const projectAddressChangeEvent = receipt?.logs.find((event) => event.eventName === "ChangedProjectAddress");
      expect(projectAddressChangeEvent).to.exist;
      await expect(repERC20.connect(community).changeProjectAddress(community.address)).to.be.rejectedWith("RepERC20: Incorrect privilege")

    });
  });
});
