// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRepFactory.sol";
import {ContinuousTokenLibrary} from "./libraries/ContinousTokenLibrary.sol";
import {RepERC20} from "./RepERC20.sol";

contract RepFactory is Ownable, IRepFactory {
    address private _feeTaker;
    uint256 private _mintingFeeBPS;
    uint256 public repCreationFee;
    uint256 constant private baseBPS = 10000;

    mapping(string => mapping(address => address)) public getRepAddress;
    address[] public allReps;

    constructor(uint256 _initialMintingFeeBPS, uint256 _repCreationFee) {
        require(_initialMintingFeeBPS > 0, "Invalid fee");

        _mintingFeeBPS = _initialMintingFeeBPS;
        repCreationFee = _repCreationFee;
        _feeTaker = msg.sender;
    }

    function mintingFeeBPS() external view returns (uint256) {
        return _mintingFeeBPS;
    }

    function allRepsLength() external view returns (uint) {
        return allReps.length;
    }

    function getFeeTaker() external view override returns (address) {
        return _feeTaker;
    }

    function createRep(string memory projectTicker, address projectAddress, uint256 projectRoyalty) external payable returns (address repToken) {
        require(projectRoyalty <= baseBPS, "Incorrect royalty set");
        require(projectAddress != address(0), 'Incorrect project address');
        require(getRepAddress[projectTicker][projectAddress] == address(0), 'You have created a REP with this Ticker before');
        require(msg.value >= repCreationFee, "Incorrect rep creation fee");

        bytes memory bytecode = abi.encodePacked(type(RepERC20).creationCode, abi.encode(projectRoyalty, projectAddress, projectTicker));
        bytes32 salt = keccak256(abi.encodePacked(projectTicker, projectAddress));

        assembly {
            repToken := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        getRepAddress[projectTicker][projectAddress] = repToken;
        allReps.push(repToken);
        emit RepCreated(projectTicker, projectAddress, repToken, allReps.length);

        payable(_feeTaker).transfer(msg.value);
    }

    function setMintingFee(uint256 newFee) external override onlyOwner {
        uint256 oldFee =_mintingFeeBPS;
        _mintingFeeBPS = newFee;

        emit ChangedMintingFee(oldFee, newFee);
    }

    function setCreationFee(uint256 newFee) external override onlyOwner {
        uint256 oldFee = repCreationFee;
        repCreationFee = newFee;

        emit ChangedCreationFee(oldFee, newFee);
    }

    function setFeeTaker(address newFeeTaker) external override onlyOwner {
        address oldAddress = _feeTaker;
        _feeTaker = payable(newFeeTaker);

        emit ChangedFeeTakerAddress(oldAddress, newFeeTaker);
    }
}
