pragma solidity ^0.5.0;

/// @title Token Farm
/// @author Nick Pala
/// @notice You can use this contract for stake and farm token
/// @dev All function calls are currently implemented without side effects

import "./DappToken.sol";
import "./DaiToken.sol";
import "@chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

contract TokenFarm {

  /// @notice Set the basic infos
  /// @dev public

    ///@dev AggregatorV3Interface, allows us to use the simplified functions of getLatestPrice
    AggregatorV3Interface private priceFeed;

    string public name = "Dapp Token Farm";
    address public owner;
    DappToken public dappToken;
    DaiToken public daiToken;

    ///address checking for staking,

    //address
    address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    /// circuitBreaker boolean
    bool isActive = true;

    constructor(DappToken _dappToken, DaiToken _daiToken) public {
        dappToken = _dappToken;
        daiToken = _daiToken;
        owner = msg.sender;
        //@dev  The oracle address is 0x9326BFA02ADD2366b30bacB125260Af641031331 and you can find all available feeds at https://docs.chain.link/docs/reference-contracts.
        priceFeed = AggregatorV3Interface(
          0x9326BFA02ADD2366b30bacB125260Af641031331
        );
    }

    /// @notice circuit braker
    /// @dev starting circuit braker, added to stakeTokens and unstakeTokens
    function toggleCircuitBreaker() external {
      require(owner == msg.sender);
      //isActive is set !banged
      isActive = !isActive;
    }
    /// @notice circuit braker
    /// @dev modifier circuit braker
    modifier contractIsActive() {
      require(isActive == true);
      _;
    }

    function stakeTokens(uint _amount) public contractIsActive() {
        //@dev Require amount greater than 0
        require(_amount > 0, "amount cannot be 0");

        //@dev Trasnfer Mock Dai tokens to this contract for staking
        daiToken.transferFrom(msg.sender, address(this), _amount);

        //@dev Update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        //@dev Add user to stakers array *only* if they haven't staked already
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        //@dev Update staking status
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    // Unstaking Tokens (Withdraw)
    function unstakeTokens() public contractIsActive() {
        //@dev Fetch staking balance
        uint balance = stakingBalance[msg.sender];

        //@dev Require amount greater than 0
        require(balance > 0, "staking balance cannot be 0");

        ///@dev Transfer Mock Dai tokens to this contract for staking
        daiToken.transfer(msg.sender, balance);

        ///@dev Reset staking balance
        stakingBalance[msg.sender] = 0;

        ///@dev Update staking status
        isStaking[msg.sender] = false;
    }

    // Issuing Tokens
    function issueTokens() public {
        ///@dev Only owner can call this function
        require(msg.sender == owner, "caller must be the owner");

        // Issue tokens to all stakers
        /// @dev simple iteration to issue tokens
        for (uint i=0; i<stakers.length; i++) {
            address recipient = stakers[i];
            uint balance = stakingBalance[recipient];

            if(balance > 0) {
                dappToken.transfer(recipient, balance);
            }
        }
    }

    /// @notice chainlink oracle ETH/USD
    /// @dev starting circuit braker, added to stakeTokens and unstakeTokens
    /// To get the latest price, just call the getLatestPrice function and it will return
    function getLatestPrice() public view returns (
        uint80 roundID,
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) {
        (
            roundID,
            price,
            startedAt,
            timeStamp,
            answeredInRound
        ) = priceFeed.latestRoundData();
    }

}
