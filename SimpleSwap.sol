// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title SimpleSwap
/// @author Pablo Maestu
/// @notice A simplified, single-pair Automated Market Maker (AMM) contract that allows for token swaps and liquidity provision.
/// @dev This contract implements the core logic of a Uniswap V2 pair without fees, focusing on clarity, security, and gas efficiency.
contract SimpleSwap is ERC20 {

    /// @notice The first token of the trading pair. The address is set at deployment and cannot be changed.
    address public immutable token0;
    /// @notice The second token of the trading pair. The address is set at deployment and cannot be changed.
    address public immutable token1;

    /// @notice The reserve of token0 held by this contract.
    uint public reserve0;
    /// @notice The reserve of token1 held by this contract.
    uint public reserve1;

    /// @dev Modifier to ensure a transaction is executed before its deadline.
    modifier ensure(uint deadline) {
        require(block.timestamp <= deadline, "SimpleSwap: EXPIRED");
        _;
    }

    /// @notice Emitted when liquidity is added to the pool.
    event LiquidityAdded(address indexed provider, uint amount0, uint amount1, uint liquidity);
    /// @notice Emitted when liquidity is removed from the pool.
    event LiquidityRemoved(address indexed provider, uint amount0, uint amount1);
    /// @notice Emitted when a token swap is executed.
    event SwapExecuted(address indexed user, address indexed tokenIn, address indexed tokenOut, uint amountIn, uint amountOut);

    /// @notice Initializes the contract with a specific pair of tokens and sets up the LP token.
    /// @param _token0 The address of the first ERC20 token.
    /// @param _token1 The address of the second ERC20 token.
    constructor(
        address _token0,
        address _token1
    ) ERC20("SimpleSwap LP Token", "SSLP") {
        require(_token0 != address(0) && _token1 != address(0), "SimpleSwap: ZERO_ADDRESS");
        require(_token0 != _token1, "SimpleSwap: IDENTICAL_ADDRESSES");
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @notice Adds liquidity to the token pair pool.
     * @param tokenA The address of one token in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param amountADesired The desired amount of tokenA to add.
     * @param amountBDesired The desired amount of tokenB to add.
     * @param amountAMin The minimum amount of tokenA to add, for slippage protection.
     * @param amountBMin The minimum amount of tokenB to add, for slippage protection.
     * @param to The address that will receive the LP (Liquidity Provider) tokens.
     * @param deadline The timestamp after which the transaction will be reverted.
     * @return amountA The actual amount of tokenA deposited.
     * @return amountB The actual amount of tokenB deposited.
     * @return liquidity The amount of LP tokens minted.
     */

function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
    // --- 1. CHECKS ---
    require((tokenA == token0 && tokenB == token1) || (tokenA == token1 && tokenB == token0), "SimpleSwap: INVALID_TOKENS");

    // --- 2. CALCULATIONS ---
    (uint _reserve0, uint _reserve1) = (reserve0, reserve1);

    if (_reserve0 == 0 && _reserve1 == 0) {
        (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
        uint amountBOptimal = (amountADesired * _reserve1) / _reserve0;
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, "SimpleSwap: INSUFFICIENT_B_AMOUNT");
            (amountA, amountB) = (amountADesired, amountBOptimal);
        } else {
            uint amountAOptimal = (amountBDesired * _reserve0) / _reserve1;
            require(amountAOptimal >= amountAMin, "SimpleSwap: INSUFFICIENT_A_AMOUNT");
            (amountA, amountB) = (amountAOptimal, amountBDesired);
        }
    }

    (uint amount0, uint amount1) = (tokenA == token0) ? (amountA, amountB) : (amountB, amountA);

    // --- 3. EFFECTS ---
    uint totalLPSupply = totalSupply();
    if (totalLPSupply == 0) {
        liquidity = sqrt(amount0 * amount1);
    } else {
        liquidity = min((amount0 * totalLPSupply) / _reserve0, (amount1 * totalLPSupply) / _reserve1);
    }
    require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_MINTED");
    _mint(to, liquidity);

    _update(_reserve0 + amount0, _reserve1 + amount1);
    emit LiquidityAdded(msg.sender, amount0, amount1, liquidity);

    // --- 4. INTERACTIONS ---
    IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
    IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);
}

    /**
     * @notice Removes liquidity from the pool.
     * @param tokenA The address of one token in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param liquidity The amount of LP tokens to burn.
     * @param amountAMin The minimum amount of tokenA to receive.
     * @param amountBMin The minimum amount of tokenB to receive.
     * @param to The address that will receive the underlying tokens.
     * @param deadline The timestamp after which the transaction will be reverted.
     * @return amountA The actual amount of tokenA received.
     * @return amountB The actual amount of tokenB received.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint amountA, uint amountB) {
        // --- 1. CHECKS ---
        require((tokenA == token0 && tokenB == token1) || (tokenA == token1 && tokenB == token0), "SimpleSwap: INVALID_TOKENS");
        
        // --- 2. CALCULATIONS ---
        (uint _reserve0, uint _reserve1) = (reserve0, reserve1);
        uint totalLPSupply = totalSupply();
        uint amount0 = (liquidity * _reserve0) / totalLPSupply;
        uint amount1 = (liquidity * _reserve1) / totalLPSupply;

        (amountA, amountB) = (tokenA == token0) ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "SimpleSwap: INSUFFICIENT_A_OUTPUT");
        require(amountB >= amountBMin, "SimpleSwap: INSUFFICIENT_B_OUTPUT");

        // --- 3. EFFECTS ---
        _burn(msg.sender, liquidity);
        _update(_reserve0 - amount0, _reserve1 - amount1);
        emit LiquidityRemoved(msg.sender, amount0, amount1);

        // --- 4. INTERACTIONS ---
        IERC20(token0).transfer(to, amount0);
        IERC20(token1).transfer(to, amount1);
    }

    /**
     * @notice Swaps an exact amount of an input token for as much as possible of an output token.
     * @dev This function does not return values as per the verifier's interface.
     * @param amountIn The exact amount of tokens being sent in.
     * @param amountOutMin The minimum amount of output tokens that must be received.
     * @param path The token addresses for the swap: [tokenIn, tokenOut].
     * @param to The recipient of the output tokens.
     * @param deadline The timestamp after which the transaction will be reverted.
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) {
        // --- 1. CHECKS ---
        require(path.length == 2, "SimpleSwap: INVALID_PATH");
        require((path[0] == token0 && path[1] == token1) || (path[0] == token1 && path[1] == token0), "SimpleSwap: INVALID_PAIR");
        
        address tokenIn = path[0];
        address tokenOut = path[1];
        (uint reserveIn, uint reserveOut) = (tokenIn == token0) ? (reserve0, reserve1) : (reserve1, reserve0);
        
        // --- 2. CALCULATIONS ---
        uint amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");

        // --- 3. EFFECTS ---
        (uint _reserve0, uint _reserve1) = (reserve0, reserve1); // Load reserves again before update
        if (tokenIn == token0) {
            _update(_reserve0 + amountIn, _reserve1 - amountOut);
        } else {
            _update(_reserve1 + amountIn, _reserve0 - amountOut);
        }
        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        
        // --- 4. INTERACTIONS ---
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(to, amountOut);
    }

    /// @notice Returns the price of tokenA in terms of tokenB.
    /// @param tokenA The address of the token to be priced.
    /// @param tokenB The address of the token used as the denomination.
    /// @return price The amount of tokenB equivalent to 1e18 units of tokenA.
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        require((tokenA == token0 && tokenB == token1) || (tokenA == token1 && tokenB == token0), "SimpleSwap: INVALID_TOKENS");
        require(reserve0 > 0 && reserve1 > 0, "SimpleSwap: NO_LIQUIDITY");

        if (tokenA == token0) {
            return (reserve1 * 1e18) / reserve0;
        } else {
            return (reserve0 * 1e18) / reserve1;
        }
    }

    /// @notice Calculates the output amount for a given input amount and reserves.
    /// @param amountIn The amount of the input token.
    /// @param reserveIn The reserve of the input token in the pool.
    /// @param reserveOut The reserve of the output token in the pool.
    /// @return amountOut The calculated amount of the output token.
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY");
        // Formula: amountOut = (amountIn * reserveOut) / (reserveIn + amountIn)
        uint numerator = amountIn * reserveOut;
        uint denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }

    // --- Internal Helper Functions ---

    /// @dev Updates the contract's reserve balances.
    function _update(uint _reserve0, uint _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    /// @dev Computes square root of a number using Babylonian method.
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @dev Returns the smaller of two numbers.
    function min(uint x, uint y) internal pure returns (uint z) {
        return x < y ? x : y;
    }
}