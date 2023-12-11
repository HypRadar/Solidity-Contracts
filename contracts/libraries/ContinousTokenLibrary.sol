// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {UD60x18, ud, convert, intoUint256} from "@prb/math/src/UD60x18.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

library ContinuousTokenLibrary {
    using SafeMath for uint256;
    uint256 private constant RESERVE_RATIO = 0.3333e18; // 1/n
    uint256 private constant SLOPE = 0.003e18;
    uint256 private constant SCALE = 1e18;
    uint256 private constant CONTINOUS_INCREASE_RATE = 3; // continous token increase rate n + 1
    uint internal constant MINIMUM_AMOUNT_VALUE = 10**10;

    /**
        @dev given a token supply, reserve, CRR and a deposit amount (in the reserve token), calculates the return for a given change (in the main token)

        Formula:
        Return = _supply * ((1 + _depositAmount / _reserveBalance) ^ _reserveRatio - 1)

        @param _supply             token total supply
        @param _reserveBalance     total reserve
        @param _depositAmount      deposit amount, in reserve token

        @return purchase return amount
    */
    function calcBancorTargetAmount(
        uint256 _supply,
        uint256 _reserveBalance,
        uint256 _depositAmount
    ) internal pure returns (uint256) {
        // validate input
        require(_depositAmount >= MINIMUM_AMOUNT_VALUE, "Invalid amount extered: p");
        require(
            _supply > 0 && _reserveBalance > 0,
            "Incorrect input parameters"
        );

        if (_depositAmount == 0) return 0;

        // ((((_depositAmount + _reserveBalance) / _reserveBalance) ** _reserveRatio) * _supply) - _supply
        UD60x18 term1 = ud(
            ((_depositAmount.add(_reserveBalance)) / _reserveBalance) * SCALE
        );
        uint256 term2 = intoUint256(term1.pow(ud(RESERVE_RATIO)));
        uint256 term3 = term2.mul(_supply) / SCALE;

        return term3.sub(_supply);
    }

    /**
        @dev given a token supply, slope, reserve ratio and a deposit amount (in the reserve token), calculates the return for a given change (in the main token)

        Formula:
        Return = (((((3*_depositAmount)/slope) + (_supply^3)) ^ _reserveRatio) - _supply)

        @param _supply             token total supply
        @param _depositAmount      deposit amount, in reserve token

        @return purchase return amount
    */
    function calcPolynomialTargetAmount(
        uint256 _supply,
        uint256 _depositAmount
    ) internal pure returns (uint256) {
        require(_depositAmount >= MINIMUM_AMOUNT_VALUE, "Invalid amount extered: p");
        if (_depositAmount == 0) return 0;

        // this is the same as (((n+1) * _depositAmount) / SLOPE) + _supply ^ (n+1)
        UD60x18 term1 = ud(
            1000 * _depositAmount + _supply ** CONTINOUS_INCREASE_RATE
        );

        uint256 term2 = intoUint256(term1.pow(ud(RESERVE_RATIO)));

        return term2.sub(_supply);
    }

    /**
        @dev given a token supply, reserve, reserve ratio and a sell amount (in the main token), calculates the return for a given change (in the reserve token)

        Formula:
        Return = _reserveBalance * (1 - (1 - _sellAmount / _supply) ^ (1 / _reserveRatio))

        @param _supply             token total supply
        @param _reserveBalance     total reserve
        @param _sellAmount         sell amount, in the token itself

        @return sale return amount
    */
    function calculateSaleReturn(
        uint256 _supply,
        uint256 _reserveBalance,
        uint256 _sellAmount
    ) internal pure returns (uint256) {
        // validate input
        require(_sellAmount >= MINIMUM_AMOUNT_VALUE, "Invalid amount extered: p");
        require(
            _supply > 0 &&
                _reserveBalance > 0 &&
                _sellAmount >= MINIMUM_AMOUNT_VALUE &&
                _sellAmount <= _supply, "incorrect input parameter"
        );

        // special case for 0 sell amount
        if (_sellAmount == 0) {
            return 0;
        }

        // special case for selling the entire supply
        if (_sellAmount == _supply) {
            return _reserveBalance;
        }

        UD60x18 term1 = ud(
            ((1 * SCALE) - (_sellAmount * SCALE) / _supply) * SCALE
        );
        uint256 term2 = (((1 * SCALE) * SCALE) / RESERVE_RATIO);
        uint256 term3 = intoUint256(term1.pow(ud(term2)));
        uint256 term4 = (((1 * SCALE) * SCALE) - term3) / SCALE;
        uint256 term5 = _reserveBalance.mul(term4);

        return term5.div(SCALE);
    }
}
