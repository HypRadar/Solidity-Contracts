// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IRepFactory {
    function mintingFeeBPS() external view returns (uint256);
    function getFeeTaker() external view returns (address);

    function getRepAddress(string memory projectTicker, address projectAddress) external view returns (address repToken);
    function allReps(uint) external view returns (address repToken);
    function allRepsLength() external view returns (uint);

    function createRep(string memory projectTicker, address projectAddress, uint256 projectRoyalty) external payable returns (address repToken);
    function setFeeTaker(address) external;
    function setMintingFee(uint256 newFee) external;
    function setCreationFee(uint256 newFee) external;

    event RepCreated(string indexed projectTicker, address indexed projectAddress, address repTokeb, uint);
    event ChangedCreationFee(uint256 olderFee, uint256 newFee);
    event ChangedMintingFee(uint256 olderFee, uint256 newFee);
    event ChangedFeeTakerAddress(address indexed older, address indexed newer);
}
