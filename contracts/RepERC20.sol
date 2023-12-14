// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {BaseERC20} from "./BaseERC20.sol";
import {ContinuousTokenLibrary} from "./libraries/ContinousTokenLibrary.sol";
import "./interfaces/IRepERC20.sol";
import "./interfaces/IRepFactory.sol";
import "hardhat/console.sol";

contract RepERC20 is BaseERC20, IRepERC20 {
    IRepFactory public factory;
    address payable public projectAddress;
    uint256 public projectRoyaltyInBPS;
    uint256 private BPSScale = 10000;

    modifier ensureDeadline(uint deadline) {
        require(
            deadline >= block.timestamp && deadline <= block.timestamp + 3600,
            "RepERC20: Transaction expired or above an hour"
        );
        _;
    }

    modifier ensureProjectAddress(address txSender) {
        require(
            projectAddress == txSender,
            "RepERC20: Incorrect privilege"
        );
        _;
    }

    constructor() {
        factory = IRepFactory(msg.sender);
    }

    // called once by the factory at time of deployment
    function initialize(uint256 _communitRoyalty,
        address _projectAddress,
        string memory projectName,
        string memory projectTicker) external override {
        require(msg.sender == address(factory), "Incorrect previlege");

        projectRoyaltyInBPS = _communitRoyalty;
        projectAddress = payable(_projectAddress);
        _initializeERC20(projectName, projectTicker);
    }

    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint256 _depositAmount
    ) external pure returns (uint256) {
        if (_supply == 0) {
            return
                ContinuousTokenLibrary.calcPolynomialTargetAmount(
                    _supply,
                    _depositAmount
                );
        }

        return
            ContinuousTokenLibrary.calcBancorTargetAmount(
                _supply,
                _reserveBalance,
                _depositAmount
            );
    }

    function calculateSaleReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint256 _sellAmount
    ) external pure returns (uint256) {
        return
            ContinuousTokenLibrary.calculateSaleReturn(
                _supply,
                _reserveBalance,
                _sellAmount
            );
    }

    function mint(
        uint amountOutMin,
        uint deadline
    ) external payable override ensureDeadline(deadline) returns (uint256) {
        require(msg.value > 0, "RepERC20: Incorrect mint amount");
        (
            uint256 newValue,
            uint256 projectRoyalty,
            uint256 mintFee
        ) = _mintFeesTaker(msg.value);

        require(
            newValue >= amountOutMin,
            "RepERC20: Output amount does not match expectation"
        );

        uint256 reserveBalance = address(this).balance;
        uint256 coinMint = this.calculatePurchaseReturn(
            this.totalSupply(),
            reserveBalance,
            newValue
        );
        _mint(msg.sender, coinMint);

        emit Mint(msg.sender, coinMint);

        payable(factory.getFeeTaker()).transfer(mintFee);
        if(projectRoyalty > 0) {
            projectAddress.transfer(projectRoyalty);
        }
        return coinMint;
    }

    function burn(
        uint256 value,
        uint amountOutMin,
        uint deadline
    ) external override ensureDeadline(deadline) returns (uint256) {
        require(value > 0, "RepERC20: Incorrect mint amount");

        uint256 reserveBalance = address(this).balance;
        uint256 coinMint = this.calculateSaleReturn(
            this.totalSupply(),
            reserveBalance,
            value
        );

        (uint256 amount, uint256 mintFee) = _burnFeesTaker(coinMint);

        require(
            amount >= amountOutMin,
            "RepERC20: Output amount does not match expectation"
        );

        _burn(msg.sender, value);

        emit Burn(msg.sender, amount, address(0));

        payable(factory.getFeeTaker()).transfer(mintFee);
        payable(msg.sender).transfer(amount);
        return amount;
    }

    function changeProjectAddress(
        address newAddress
    ) external override ensureProjectAddress(msg.sender) {
        address oldAddress = projectAddress;
        projectAddress = payable(newAddress);

        emit ChangedProjectAddress(oldAddress, newAddress);
    }

    function _calcProjectRoyalty(
        uint256 value
    ) internal view returns (uint256 royaltyFee) {
        if (projectRoyaltyInBPS == 0) return 0;
        royaltyFee = (value * projectRoyaltyInBPS) / BPSScale;
    }

    function _calcMintFee(
        uint256 value
    ) internal view returns (uint256 royaltyFee) {
        if (factory.mintingFeeBPS() == 0) return 0;
        royaltyFee = (factory.mintingFeeBPS() * value) / BPSScale;
    }

    function _mintFeesTaker(
        uint256 value
    ) internal view returns (uint256, uint256, uint256) {
        uint256 newValue = value;

        uint256 projectRoyalty = _calcProjectRoyalty(value);
        uint256 mintFee = _calcMintFee(value);

        uint256 fees = projectRoyalty + mintFee;
        newValue -= fees;

        return (newValue, projectRoyalty, mintFee);
    }

    function _burnFeesTaker(
        uint256 value
    ) internal view returns (uint256, uint256) {
        uint256 newValue = value;
        uint256 mintFee = _calcMintFee(value);

        newValue -= mintFee;

        return (newValue, mintFee);
    }
}
