// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "v4-periphery/BaseHook.sol";

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";

contract TradingHours is BaseHook {
    using PoolId for IPoolManager.PoolKey;

    uint256 public constant openingTime = 60 * 60 * 8; // 08:00
    uint256 public constant closingTime = 60 * 60 * 16; // 16:00

    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: false,
            afterInitialize: false,
            beforeModifyPosition: false,
            afterModifyPosition: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function beforeSwap(address, IPoolManager.PoolKey calldata, IPoolManager.SwapParams calldata)
        external
        view
        override
        returns (bytes4)
    {
        uint256 time = block.timestamp % (60 * 60 * 24);

        require(
            time >= openingTime &&
            time < closingTime,
            "TradingHours.beforeSwap: market closed"
        );

        return BaseHook.beforeSwap.selector;
    }
}
