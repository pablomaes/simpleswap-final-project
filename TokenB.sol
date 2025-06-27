// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Token B - ERC20 Token for SimpleSwap testing
/// @author Pablo Maestu
/// @notice This token is mintable and will be used as TokenB in the liquidity pool
contract TokenB is ERC20, Ownable {
    /// @notice Constructor that initializes TokenA with initial supply to deployer
    constructor() ERC20("Token B", "TKB") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 ether);
    }

    /// @notice Mints new tokens to a specified address.
    /// @dev Can only be called by the contract owner.
    /// @param to The address that will receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}