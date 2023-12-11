// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IRepERC20 {
    function mint(
        uint amountOutMin,
        uint deadline
    ) external payable returns (uint256 amount);

    function burn(
        uint256 value,
        uint amountOutMin,
        uint deadline
    ) external returns (uint256 amount);

    function changeProjectAddress(address newAddress) external;

    function calculatePurchaseReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint256 _depositAmount
    ) external pure returns (uint256);

    function calculateSaleReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint256 _sellAmount
    ) external pure returns (uint256);

    event ChangedProjectAddress(address indexed older, address indexed newer);
    event Mint(address indexed sender, uint256 amount);
    event Burn(address indexed sender, uint256 amount, address indexed to);
}
