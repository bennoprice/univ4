// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolId} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/contracts/libraries/CurrencyLibrary.sol";
import {HookTest} from "./utils/HookTest.sol";
import {TradingHours} from "../src/TradingHours.sol";
import {TradingHoursImplementation} from "./implementation/TradingHoursImplementation.sol";

contract MarketHoursTest is HookTest, Deployers, GasSnapshot {
    using PoolId for IPoolManager.PoolKey;
    using CurrencyLibrary for Currency;

    TradingHours tradingHours = TradingHours(address(uint160(Hooks.BEFORE_SWAP_FLAG)));
    IPoolManager.PoolKey poolKey;
    bytes32 poolId;

    function setUp() public {
        // creates the pool manager, test tokens, and other utility routers
        HookTest.initHookTestEnv();

        // testing environment requires our contract to override `validateHookAddress`
        // well do that via the Implementation contract to avoid deploying the override with the production contract
        TradingHoursImplementation impl = new TradingHoursImplementation(manager, tradingHours);
        etchHook(address(impl), address(tradingHours));

        // Create the pool
        poolKey = IPoolManager.PoolKey(
            Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(tradingHours)
        );
        poolId = PoolId.toId(poolKey);
        manager.initialize(poolKey, SQRT_RATIO_1_1);

        // Provide liquidity to the pool
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-60, 60, 10 ether));
        modifyPositionRouter.modifyPosition(poolKey, IPoolManager.ModifyPositionParams(-120, 120, 10 ether));
        modifyPositionRouter.modifyPosition(
            poolKey, IPoolManager.ModifyPositionParams(TickMath.minUsableTick(60), TickMath.maxUsableTick(60), 10 ether)
        );
    }

    function testTradingHoursHooks() public {
        vm.warp(1689994800); // 05:00
        vm.expectRevert();
        swap(poolKey, 100, true);

        vm.warp(1690056000); // 22:00
        vm.expectRevert();
        swap(poolKey, 100, true);

        vm.warp(1690016400); // 11:00
        swap(poolKey, 100, true);
    }
}
