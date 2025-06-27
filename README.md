# SimpleSwap: 
This project is the Final Assignment for Module 3, designed to implement a decentralized Automated Market Maker (AMM) exchange for a single token pair from scratch.

**Author:** Pablo Maestu
**Professor's Verifier Index:** 74

---

## 📜 General Description

`SimpleSwap` is a smart contract that emulates the core functionality of a Uniswap V2-style liquidity pair. It allows users to perform three fundamental operations: adding liquidity, removing liquidity, and swapping tokens. The design focuses on simplicity, security, and gas efficiency, strictly adhering to the provided specifications and recommendations.

The project ecosystem consists of three smart contracts:
1.  **TokenA.sol**: An ERC20 test token (`TKA`).
2.  **TokenB.sol**: An ERC20 test token (`TKB`).
3.  **SimpleSwap.sol**: The main contract that orchestrates the liquidity pool and all swap operations.

## 🔗 Deployed Contracts on Sepolia

All contracts have been successfully deployed and verified on the Sepolia testnet. They can be interacted with via Etherscan.

-   **TokenA (TKA):** [`0x8Cf5e8a86bE4EAe2130Bd2d67933c30E9574349`](https://sepolia.etherscan.io/address/0x8Cf5e8a86bE4EAe2130Bd2d67933c30E9574349c#code)
-   **TokenB (TKB):** [`0xcE03bFdf7664D6112873406ddE1cb9646d067Fd5`](https://sepolia.etherscan.io/address/0xcE03bFdf7664D6112873406ddE1cb9646d067Fd5#code)
-   **SimpleSwap:** [`0xcD7f2045B8478Ca65f2f7BF34f066fED47aea490`](https://sepolia.etherscan.io/address/0xcD7f2045B8478Ca65f2f7BF34f066fED47aea490#code)

## ✨ Features & Functionality

The `SimpleSwap` contract implements the following public interface:

-   `addLiquidity`: Allows users to deposit a pair of tokens to receive LP (Liquidity Provider) tokens in return, representing their share of the pool.
-   `removeLiquidity`: Allows LP token holders to burn them to withdraw their corresponding share of the underlying tokens from the pool.
-   `swapExactTokensForTokens`: Facilitates the swap of an exact amount of an input token for the maximum possible amount of an output token, based on the constant product formula `x * y = k`.
-   `getPrice`: Returns the instantaneous price of `tokenA` in terms of `tokenB`, scaled by 1e18 to handle decimals.
-   `getAmountOut`: A `pure` function that calculates the output amount for a given input amount, allowing user interfaces to preview trades.

## 🛠️ Design Decisions & Best Practices

To ensure the quality, security, and efficiency of the contract, the following key design decisions were made:

1.  **Single, Fixed-Pair Architecture:** Following the professor's explicit recommendation, the contract is designed to handle a single token pair. The addresses of these tokens are set as `immutable` variables in the constructor. This design choice drastically simplifies the logic (eliminating the need for `sortTokens`), prevents errors, and significantly optimizes gas consumption, as `immutable` reads are much cheaper than `storage` reads.

2.  **Gas Optimization:** Several techniques were applied to minimize transaction costs:
    -   Use of `immutable` state variables for the token addresses.
    -   Caching of state variables (`reserve0`, `reserve1`, `totalSupply()`) into local memory variables at the beginning of functions to avoid multiple expensive `SLOAD` operations.
    -   Use of short, specific error messages (e.g., `"SimpleSwap: EXPIRED"`) instead of long strings.

3.  **Security (Checks-Effects-Interactions Pattern):** All functions that modify state and interact with other contracts (`addLiquidity`, `removeLiquidity`, `swapExactTokensForTokens`) rigorously follow this security pattern. Validations (`Checks`) are performed first, followed by internal state changes (`Effects`), and finally, calls to external contracts (`Interactions`) are made. This is a critical measure to prevent re-entrancy vulnerabilities.

4.  **Adherence to the Verifier's Interface:** The contract aligns perfectly with the `ISimpleSwap` interface provided in the verifier contract. This includes matching the function signature for `swapExactTokensForTokens` with no return value, thus ensuring compatibility for the final test.

## ✅ Successful Verification

The contract has been successfully tested and has passed all assertions of the official `SwapVerifier` on the Sepolia network.

-   **Verifier Contract Address:** `0x9f8f02dab384dddf1591c3366069da3fb0018220`
-   **Proof of Execution (Successful Transaction Hash):** [`0x81e26c0a446eb4a589e0c0ba0e11eccf1f32d244143da206b87e5e829367ccee`](https://sepolia.etherscan.io/tx/0x81e26c0a446eb4a589e0c0ba0e11eccf1f32d244143da206b87e5e829367ccee)

---
