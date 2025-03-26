// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title LLEDUERC20
 * @notice A minimal ERC20 token that you control. 
 *         By default, you are the minter and can create tokens as needed.
 */
contract LLEDUERC20 is ERC20 {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @notice Constructor mints initial supply to the owner.
     * @param _name Name of the token
     * @param _symbol Symbol of the token
     * @param _initialSupply Initial supply to mint (decimals = 18)
     * @param _owner The address with authority (e.g., can mint more)
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _owner
    ) ERC20(_name, _symbol) {
        owner = _owner;
        _mint(_owner, _initialSupply);
    }

    /**
     * @notice Mint additional tokens to any address. Only callable by the owner.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Change ownership if needed.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }
}
