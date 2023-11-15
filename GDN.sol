// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GuildNetToken is ERC20, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * (10 ** 18);
    mapping(address => uint256) public vestingBalance;
    mapping(address => uint256) public nextReleaseTime;
    mapping(address => uint256) public releaseRate;

    address public ecosystemWallet;
    address public treasuryWallet;
    address public communityWallet;
    address public marketingWallet;
    address public contributorsWallet;

    mapping(address => uint256) public stakes;
    mapping(address => uint256) public nextUnstakeTime;
    uint256 public lockTime = 1 days;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event TokensReleased(address indexed wallet, uint256 amount);

    constructor() ERC20("GuildNet Token", "GDN") {
        // 15% for IEO and 5% for Liquidity Providing
        uint256 initialMint = 200_000_000 * (10 ** 18);
        _mint(msg.sender, initialMint);

        ecosystemWallet = msg.sender;
        treasuryWallet = msg.sender;
        communityWallet = msg.sender;
        marketingWallet = msg.sender;
        contributorsWallet = msg.sender;

        setupVesting();
    }

    // Constructor function to setup vesting rules
    function setupVesting() private {
        vestingBalance[ecosystemWallet] = 250_000_000 * (10 ** 18);
        releaseRate[ecosystemWallet] = 2_976_190 * (10 ** 18);
        nextReleaseTime[ecosystemWallet] = block.timestamp + 1 days;

        vestingBalance[treasuryWallet] = 200_000_000 * (10 ** 18);
        releaseRate[treasuryWallet] = 2_380_952  * (10 ** 18);
        nextReleaseTime[treasuryWallet] = block.timestamp + 1 days;

        vestingBalance[communityWallet] = 50_000_000 * (10 ** 18);
        releaseRate[communityWallet] = 2_173_913 * (10 ** 18);
        nextReleaseTime[communityWallet] = block.timestamp + 30 days;

        vestingBalance[marketingWallet] = 150_000_000 * (10 ** 18);
        releaseRate[marketingWallet] = 25_000_000 * (10 ** 18);
        nextReleaseTime[marketingWallet] = block.timestamp + 365 days;

        vestingBalance[contributorsWallet] = 150_000_000 * (10 ** 18);
        releaseRate[contributorsWallet] = 25_000_000 * (10 ** 18);
        nextReleaseTime[contributorsWallet] = block.timestamp + 365 days;
    }

    function releaseVestedTokens(address wallet) public {
        require(msg.sender == wallet || msg.sender == owner(), "Unauthorized");
        require(block.timestamp > nextReleaseTime[wallet], "Too early to release");
        
        uint256 amount = releaseRate[wallet];
        amount = (amount > vestingBalance[wallet]) ? vestingBalance[wallet] : amount;
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");

        vestingBalance[wallet] -= amount;
        nextReleaseTime[wallet] = block.timestamp + 30 days;
        _mint(wallet, amount);

        emit TokensReleased(wallet, amount);
    }

    function stake(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        
        _burn(msg.sender, _amount);
        stakes[msg.sender] += _amount;
        nextUnstakeTime[msg.sender] = block.timestamp + lockTime;

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) public nonReentrant {
        require(block.timestamp >= nextUnstakeTime[msg.sender], "Stake is locked");
        require(stakes[msg.sender] >= _amount, "Insufficient stake");
        
        stakes[msg.sender] -= _amount;
        _mint(msg.sender, _amount);

        emit Unstaked(msg.sender, _amount);
    }

    function setLockTime(uint256 _lockTime) public onlyOwner {
        require(_lockTime > 0, "Lock time must be greater than 0");
        lockTime = _lockTime;
    }

    function setEcosystemWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0), "Address cannot be the zero address");
        ecosystemWallet = _wallet;
    }
    function setTreasuryWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0), "Address cannot be the zero address");
        treasuryWallet = _wallet;
    }
    function setCommunityWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0), "Address cannot be the zero address");
        communityWallet = _wallet;
    }
    function setMarketingWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0), "Address cannot be the zero address");
        marketingWallet = _wallet;
    }
    function setContributorsWallet(address _wallet) public onlyOwner {
        require(_wallet != address(0), "Address cannot be the zero address");
        contributorsWallet = _wallet;
    }

}
