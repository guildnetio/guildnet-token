// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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

  constructor(
  address initialOwner,
  address _ecosystemWallet,
  address _treasuryWallet,
  address _communityWallet,
  address _marketingWallet,
  address _contributorsWallet
  ) ERC20("GuildNet Token", "GDN") Ownable(initialOwner) {
      uint256 initialMint = 200_000_000 * (10 ** 18);
      _mint(initialOwner, initialMint);

      ecosystemWallet = _ecosystemWallet;
      treasuryWallet = _treasuryWallet;
      communityWallet = _communityWallet;
      marketingWallet = _marketingWallet;
      contributorsWallet = _contributorsWallet;

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

  function releaseVestedTokens(address wallet) public nonReentrant {
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
      require(totalSupply() + _amount <= MAX_SUPPLY, "Max supply exceeded");
      
      stakes[msg.sender] -= _amount;
      _mint(msg.sender, _amount);

      emit Unstaked(msg.sender, _amount);
  }

  function setLockTime(uint256 _lockTime) public onlyOwner {
      require(_lockTime > 0, "Lock time must be greater than 0");
      lockTime = _lockTime;
  }

  function updateVestingWallet(address oldWallet, address newWallet) internal {
      require(newWallet != address(0), "Address cannot be the zero address");
      require(newWallet != oldWallet, "New address is the same as current address");
      require(
            newWallet != ecosystemWallet && 
            newWallet != treasuryWallet && 
            newWallet != communityWallet && 
            newWallet != marketingWallet && 
            newWallet != contributorsWallet, 
            "Must use different wallet address for each vesting beneficiary"
        );

      vestingBalance[newWallet] = vestingBalance[oldWallet];
      nextReleaseTime[newWallet] = nextReleaseTime[oldWallet];
      releaseRate[newWallet] = releaseRate[oldWallet];

      vestingBalance[oldWallet] = 0;
      nextReleaseTime[oldWallet] = 0;
      releaseRate[oldWallet] = 0;
  }


  function setEcosystemWallet(address _wallet) public onlyOwner {
      updateVestingWallet(ecosystemWallet, _wallet);
      ecosystemWallet = _wallet;
  }

  function setTreasuryWallet(address _wallet) public onlyOwner {
      updateVestingWallet(treasuryWallet, _wallet);
      treasuryWallet = _wallet;
  }

  function setCommunityWallet(address _wallet) public onlyOwner {
      updateVestingWallet(communityWallet, _wallet);
      communityWallet = _wallet;
  }

  function setMarketingWallet(address _wallet) public onlyOwner {
      updateVestingWallet(marketingWallet, _wallet);
      marketingWallet = _wallet;
  }

  function setContributorsWallet(address _wallet) public onlyOwner {
      updateVestingWallet(contributorsWallet, _wallet);
      contributorsWallet = _wallet;
  }

}
