// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.27;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './external/INonfungiblePositionManager.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import './external/TickMath.sol';

/**
 * @title UniswapV3Connector
 * @author Pavel Grigoriev
 * @notice Allows to add liquidity to UniswapV3Pool.
 * @dev Contract accepts Pool address, token0 and token1 amounts, price range width = (upperPrice - lowerPrice) * 10000 / (lowerPrice + upperPrice).
 */
contract UniswapV3Connector {
    using SafeERC20 for IERC20;

    struct PoolInfo {
        uint160 sqrtPriceX96;
        uint8 feeProtocol;
        address token0;
        address token1;
    }

    uint256 public constant DENOMINATOR = 100_00;

    event AddedLiquidity(
        uint256 indexed tokenId,
        uint256 indexed amount0,
        uint256 indexed amount1
    );

    function addLiquidity(
        address positionManager,
        address pool,
        uint256 amount0In,
        uint256 amount1In,
        uint256 width,
        bool onlyStrictAmounts,
        uint256 accuracyNumerator
    ) external returns (uint256 tokenId, uint256 amount0, uint256 amount1) {
        require(pool != address(0), 'Invalid pool');
        require(positionManager != address(0), 'Invalid manager');

        (uint256 minAmount0, uint256 minAmount1) = _getActualMinAmounts(
            amount0In,
            amount1In,
            accuracyNumerator,
            onlyStrictAmounts
        );

        PoolInfo memory info = _getPoolInfo(pool);

        (int24 tickLower, int24 tickUpper, , ) = calculateTicks(
            info.sqrtPriceX96,
            amount0In,
            amount1In,
            width
        );

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager
            .MintParams({
                token0: info.token0,
                token1: info.token1,
                fee: info.feeProtocol,
                tickLower: tickLower,
                tickUpper: tickUpper,
                amount0Desired: amount0In,
                amount1Desired: amount1In,
                amount0Min: minAmount0,
                amount1Min: minAmount1,
                recipient: msg.sender,
                deadline: block.timestamp
            });

        (tokenId, , amount0, amount1) = INonfungiblePositionManager(positionManager).mint(
            params
        );

        emit AddedLiquidity(tokenId, amount0, amount1);
    }

    function _getPoolInfo(address pool) private view returns (PoolInfo memory info) {
        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();
        (uint160 sqrtPriceX96, , , , , uint8 feeProtocol, ) = IUniswapV3Pool(pool)
            .slot0();

        info = PoolInfo({
            sqrtPriceX96: sqrtPriceX96,
            feeProtocol: feeProtocol,
            token0: token0,
            token1: token1
        });
    }

    function calculateTicks(
        uint256 sqrtPriceX96,
        uint256 dY,
        uint256 dX,
        uint256 width
    )
        public
        pure
        returns (
            int24 tickLower,
            int24 tickUpper,
            uint256 sqrtPriceX96Lower,
            uint256 sqrtPriceX96Upper
        )
    {
        /**
         * P_b > P > P_a
         * dX > 0
         * dY > 0
         * W = (P_b - P_a) * 10^4 / (P_b + P_a)
         * P_b, P_a - ?
         *
         * dX, dY > 0 => dL_x, dL_y > 0
         *
         * dL_x = L / (1/sqrt(P) - 1/sqrt(P_b))
         * dL_y = L / (sqrt(P) - sqrt(P_a))
         *
         * T = (10^4 + W) / (10^4 - W) > 1
         * sqrt(P_a) = sqrt(P) * (dY - dX) / (sqrt(T) * dY - dX)
         * sqrt(P_b) = sqrt(P_a) * sqrt(T) = sqrt(P_a * T)
         *
         * sqrtPriceX96 = sqrt(P) * 2^96
         * P = 1.0001^tick => tick = log_1.0001(P)
         * using Uniswap TickMath::getTickAtSqrtRatio
         */

        require(width < DENOMINATOR && width != 0, 'Invalid width');

        require(dY != 0, 'Invalid amount 0');
        require(dX != 0, 'Invalid amount 1');

        uint256 tNumerator = (DENOMINATOR + width);
        uint256 tDenominator = (DENOMINATOR - width);

        uint256 sqrtTNumeratorD = Math.sqrt(tNumerator * DENOMINATOR);
        uint256 sqrtTDenominatorD = Math.sqrt(tDenominator * DENOMINATOR);

        sqrtPriceX96Lower =
            (sqrtPriceX96 * _absDiff(dY, dX) * sqrtTDenominatorD) /
            _absDiff(sqrtTNumeratorD * dY, sqrtTDenominatorD * dX);

        sqrtPriceX96Upper = (sqrtPriceX96Lower * sqrtTNumeratorD) / sqrtTDenominatorD;

        int24 tickUpperTmp = TickMath.getTickAtSqrtRatio(uint160(sqrtPriceX96Upper));
        int24 tickLowerTmp = TickMath.getTickAtSqrtRatio(uint160(sqrtPriceX96Lower));

        (tickUpper, tickLower) = tickUpperTmp > tickLowerTmp
            ? (tickUpperTmp, tickLowerTmp)
            : (tickLowerTmp, tickUpperTmp);
    }

    function _absDiff(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? a - b : b - a;
    }

    function _getActualMinAmounts(
        uint256 amount0In,
        uint256 amount1In,
        uint256 accuracyDeltaNumerator,
        bool onlyStrictAmounts
    ) private pure returns (uint256, uint256) {
        return
            onlyStrictAmounts
                ? (amount0In, amount1In)
                : (
                    (amount0In * (DENOMINATOR - accuracyDeltaNumerator)) / DENOMINATOR,
                    (amount1In * (DENOMINATOR - accuracyDeltaNumerator)) / DENOMINATOR
                );
    }
}
