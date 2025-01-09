// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract DaoBuddyService {
    address public admin;
    address public feeAddress;
    uint256 public fee;
    address public feeToken;

    bool public isPaused;
    bool public isDestroyed;

    mapping(address => bool) public allowToken;
    address[] public allowedTokens;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier notPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    modifier notDestroyed() {
        require(!isDestroyed, "Contract is destroyed");
        _;
    }

    modifier isActive() {
        require(!isPaused && !isDestroyed, "Contract is not active");
        _;
    }

    constructor() {
        admin = msg.sender;
        feeAddress = 0x98e5CFBC115b01017Ed19101357Ab0a7664f38f1;
        fee = 0.1 ether;
        feeToken = 0xE67E280f5a354B4AcA15fA7f0ccbF667CF74F97b; // Default to a specific token
    }

    function allowTokenByIndex(uint256 index) public view returns (address) {
        require(index < allowedTokens.length, "Index out of bounds");
        return allowedTokens[index];
    }

    function isAllowToken(address token) public view returns (bool) {
        return allowToken[token];
    }

    function allowedTokensCount() public view returns (uint256) {
        return allowedTokens.length;
    }

    function batchTransfer(address token, address[] calldata recipients, uint256[] calldata amounts) external notPaused isActive {
    require(allowToken[token], "Token not allowed");
    require(recipients.length == amounts.length, "Recipients and amounts length mismatch");
    
    IERC20 erc20 = IERC20(token);
    
    // Approve total amount for each recipient and transfer
    for (uint256 i = 0; i < recipients.length; i++) {
        // Approve Fee Token
        require(IERC20(feeToken).approve(address(this), fee), "Fee approval failed");
        
        // Approve Token for transfer
        require(erc20.approve(address(this), amounts[i]), "Approval failed");
        
        // Transfer
        require(erc20.transferFrom(msg.sender, recipients[i], amounts[i]), "Transfer failed");
        
        // Transfer fee
        require(IERC20(feeToken).transferFrom(msg.sender, feeAddress, fee), "Fee transfer failed");
    }
}

    function batchTransferWithFixAmount(address token, address[] calldata recipients, uint256 amountPerRecipient) external notPaused isActive {
        require(allowToken[token], "Token not allowed");
        
        IERC20 erc20 = IERC20(token);
        
        uint256 totalAmount = amountPerRecipient * recipients.length;

        // Approve total amount and fee
        require(IERC20(feeToken).approve(address(this), fee), "Fee approval failed");
        require(erc20.approve(address(this), totalAmount), "Approval failed");

        for (uint256 i = 0; i < recipients.length; i++) {
            // Transfer
            require(erc20.transferFrom(msg.sender, recipients[i], amountPerRecipient), "Transfer failed");
            
            // Transfer fee
            require(IERC20(feeToken).transferFrom(msg.sender, feeAddress, fee), "Fee transfer failed");
        }
    }


    function approveToken(address token, uint256 amount) external notPaused isActive {
        require(allowToken[token], "Token not allowed");
        IERC20(token).approve(address(this), amount);
    }

    function addAllowToken(address token) external onlyAdmin notDestroyed {
        require(!allowToken[token], "Token already allowed");
        allowToken[token] = true;
        allowedTokens.push(token);
    }

    function removeAllowToken(address token) external onlyAdmin notDestroyed {
        require(allowToken[token], "Token not allowed");
        allowToken[token] = false;

        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == token) {
                allowedTokens[i] = allowedTokens[allowedTokens.length - 1];
                allowedTokens.pop();
                break;
            }
        }
    }

    function setFeeAddress(address addr) external onlyAdmin notDestroyed {
        feeAddress = addr;
    }

    function setFeeAmount(uint256 amount) external onlyAdmin notDestroyed {
        fee = amount;
    }

    function setFeeToken(address token) external onlyAdmin notDestroyed {
        feeToken = token;
    }

    function pauseContract() external onlyAdmin notDestroyed {
        isPaused = true;
    }

    function resumeContract() external onlyAdmin notDestroyed {
        isPaused = false;
    }

    function consumeContract() external onlyAdmin notPaused {
        isDestroyed = true;
    }
}
