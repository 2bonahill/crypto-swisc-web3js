//File: node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol
pragma solidity ^0.4.21;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

//File: node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol
pragma solidity ^0.4.21;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

//File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol
pragma solidity ^0.4.21;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

//File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol
pragma solidity ^0.4.21;




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//File: node_modules/openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol
pragma solidity ^0.4.21;





/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

//File: node_modules/openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol
pragma solidity ^0.4.21;





/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

//File: node_modules/openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol
pragma solidity ^0.4.21;






/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }

}

//File: node_modules/openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol
pragma solidity ^0.4.21;





/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   */
  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

//File: node_modules/openzeppelin-solidity/contracts/crowdsale/validation/WhitelistedCrowdsale.sol
pragma solidity ^0.4.21;





/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

  /**
   * @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract.
   */
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  /**
   * @dev Adds single address to whitelist.
   * @param _beneficiary Address to be added to the whitelist
   */
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }

  /**
   * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
   * @param _beneficiaries Addresses to be added to the whitelist
   */
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  /**
   * @dev Removes single address from whitelist.
   * @param _beneficiary Address to be removed to the whitelist
   */
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

  /**
   * @dev Extend parent behavior requiring beneficiary to be in whitelist.
   * @param _beneficiary Token beneficiary
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

//File: node_modules/openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol
pragma solidity ^0.4.21;






/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

//File: node_modules/openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol
pragma solidity ^0.4.21;





/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

//File: node_modules/openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol
pragma solidity ^0.4.21;





/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

//File: node_modules/openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol
pragma solidity ^0.4.21;





/**
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting.
 */
contract MintedCrowdsale is Crowdsale {

  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

//File: node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol
pragma solidity ^0.4.21;





/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

//File: contracts/crowdsale/SWISCCrowdsale.sol
/**
 * @title SWISC Crowdsale
 * @version 1.0
 * @author Validity Labs AG <info@validitylabs.org>
 */
pragma solidity ^0.4.22;








contract SWISCCrowdsale is CappedCrowdsale, MintedCrowdsale, WhitelistedCrowdsale, FinalizableCrowdsale, Pausable {
    /*** CONSTANTS ***/
    uint256 public constant INITIAL_HARD_CAP = 5e6 * 1e18;    // 5 million * 1e18 - smallest unit of SWISC token
    uint256 public constant PRECISION = 18;
    address public constant SWISC_WALLET = 0x67115dFa6A942a512c0861BA5c58d74627E531A2;
    uint256 public chfTokenRate;         // standard CHF per token rate - in cents - EX: 1 CHF => 100 CHF cents - set via constructor
    // inital min investment amount - not a constant as future crowdsale can alter this amount
    uint256 public min_contribution_chf = 5000;      // minimum investment in CHF

    /*** VARIABLES ***/
    // allow managers to whitelist and confirm contributions by manager accounts
    // managers can be set and altered by owner, multiple manager accounts are possible
    mapping(address => bool) public isManager;

    uint256 public tokensMinted;    // total token supply that has been minted

    uint256 public crowdsaleRound;
    bool public disabled;   // disable crowdsale completely

    // index of SWISC Token per wei rate
    uint256[] public tokenPriceIndex;
    // index of CHF per ETH rate
    uint256[] public ethPriceIndex;
    // current price index. Note: 0 = 0 rate. Rates begin at index 1
    uint256 public currentPriceIndex;

    /*** EVENTS  ***/
    event ChangedManager(address manager, bool active);
    event NonEthTokenPurchase(uint256 investmentType, address indexed beneficiary, uint256 tokenAmount);
    event NewCrowdsaleRound(uint256 start, uint256 duration, uint256 deltaTokenCap, uint256 minContributionChf, uint256 chfTokenRate);
    event NewChfPerEtherRate(uint256 chfEthRate);

    /*** MODIFIERS ***/
    modifier onlyManager() {
        require(isManager[msg.sender]);
        _;
    }

    modifier onlyNotDisabled() {
        require(!disabled);
        _;
    }

    modifier onlyUnderCap(uint256 _amount) {
        require(tokensMinted.add(_amount) <= cap);
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0));
        _;
    }

    modifier onlyNoneZero(address _to, uint256 _amount) {
        require(_to != address(0));
        require(_amount > 0);
        _;
    }

    modifier onlyCrowdsaleOver() {
        // solium-disable-next-line security/no-block-members
        require(now >= closingTime);
        _;
    }

    modifier onlyIsFinalized() {
        require(isFinalized, "ICO is not finalized");
        _;
    }

    /**
     * @dev constructor Deploy SWISC Token Crowdsale
     * @param _startTime uint256 Start time of the crowdsale
     * @param _endTime uint256 End time of the crowdsale
     * @param _token ERC20 token address
     * @param _chfTokenRate CHF per Token
     */
    constructor(
        uint256 _startTime,
        uint256 _endTime,
        address _token,
        uint256 _chfTokenRate
        )
        Crowdsale(1, SWISC_WALLET, ERC20(_token)) // set rate to 1 to pass constructor check
        TimedCrowdsale(_startTime, _endTime)
        CappedCrowdsale(INITIAL_HARD_CAP)
        public
    {
        require(_chfTokenRate > 0, "_chfEthRate !> 0");

        chfTokenRate = _chfTokenRate;
        setManager(msg.sender, true);

        tokenPriceIndex.push(0);
        ethPriceIndex.push(0);
        rate = 0;   // set rate to 0 as it's never used
    }

    /**
    * @dev insert new rate and iterate currentPriceIndex
    * @param _chfEthRate uint256 ratio of CHF to 1 ETH
    */
    function addNewSwiscPerEtherRate(uint256 _chfEthRate) public onlyManager onlyNotDisabled {
        require(_chfEthRate > 0);
        // check for potential overflows before doing precise calculation
        uint256 testOverflow = (_chfEthRate.mul(1e2).mul(10**PRECISION).div(chfTokenRate));
        // calculate the TOK/ETH rate in 18 decimal precision
        uint256 tokenRate = (_chfEthRate * 1e2 * 10**PRECISION / chfTokenRate);
        tokenPriceIndex.push(tokenRate);
        ethPriceIndex.push(_chfEthRate);
        currentPriceIndex++;
        emit NewChfPerEtherRate(_chfEthRate);
    }

    /** !!!OVERRIDE!!!
    * @dev low level token purchase
    * @param _beneficiary Address performing the token purchase
    */
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        // calculate token amount to be created - cannot calculate as rate is not yet known
        uint256 tokens = _getTokenAmount(weiAmount);
        _preValidatePurchase(_beneficiary, weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);
        //push to investments array
        _processPurchase(_beneficiary, tokens);
        // throw event
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        // forward wei to the wallet
        _forwardFunds();
    }

    /**
     * @dev start a new crowdsale round
     * @param _start uint256 start time in unix
     * @param _duration uint256 length of crowdsale
     * @param _deltaTokenCap uint256 additional token cap to add to the previous cap
     * @param _minContributionChf uint256 minimum contribution in CHF
     * @param _chfTokenRate tokens per chf
     */
    function newCrowdsale(uint256 _start, uint256 _duration, uint256 _deltaTokenCap, uint256 _minContributionChf, uint256 _chfTokenRate)
        public
        onlyManager
        onlyCrowdsaleOver
        onlyNotDisabled
        onlyIsFinalized
    {
        // solium-disable-next-line security/no-block-members
        require(_start > now, "start time invalid");
        require(_duration > 0, "duration !> 0");
        require(_deltaTokenCap > 0, "deltaCap !> 0");
        require(_minContributionChf > 0, "minContribution !> 0");
        require(_chfTokenRate > 0, "_chfEthRate !> 0");

        openingTime = _start;
        closingTime = _start.add(_duration);
        min_contribution_chf = _minContributionChf;
        cap = cap.add(_deltaTokenCap);
        chfTokenRate = _chfTokenRate;
        isFinalized = false;
        crowdsaleRound++;

        emit NewCrowdsaleRound(_start, _duration, _deltaTokenCap, _minContributionChf, _chfTokenRate);
    }

    /**
    * @dev Checks whether the cap has been reached. *Overriden* - change to tokensMinted from weiRaised
    * only active if a cap has been set
    * @return Whether the cap was reached
    */
    function capReached() public view returns (bool) {
        return tokensMinted >= cap;
    }

    /**
     * @dev Set / alter manager / whitelister "account". This can be done from owner only
     * @param _manager address address of the manager to create/alter
     * @param _active bool flag that shows if the manager account is active
     */
    function setManager(address _manager, bool _active) public onlyOwner onlyValidAddress(_manager) {
        isManager[_manager] = _active;
        emit ChangedManager(_manager, _active);
    }

    /**
    * @dev onlyOwner allowed to allocate non-ETH investments during the crowdsale
    * @param _investmentType uint256
    * @param _beneficiary address
    * @param _tokenAmount uint256
    */
    function nonEthPurchase(uint256 _investmentType, address _beneficiary, uint256 _tokenAmount) public
        onlyManager
        onlyWhileOpen
        onlyNoneZero(_beneficiary, _tokenAmount)
        onlyUnderCap(_tokenAmount)
    {
        _processPurchase(_beneficiary, _tokenAmount);
        emit NonEthTokenPurchase(_investmentType, _beneficiary, _tokenAmount);
    }

   /**
    * @dev onlyOwner allowed to handle batches of non-ETH investments
    * @param _investmentTypes uint256[] array of ids to identify investment types IE: BTC, CHF, EUR, etc...
    * @param _beneficiaries address[]
    * @param _amounts uint256[]
    */
    function batchNonEthPurchase(uint256[] _investmentTypes, address[] _beneficiaries, uint256[] _amounts) external {
        require(_beneficiaries.length == _amounts.length && _investmentTypes.length == _amounts.length, "array lengths !=");

        for (uint256 i; i < _beneficiaries.length; i = i.add(1)) {
            nonEthPurchase(_investmentTypes[i], _beneficiaries[i], _amounts[i]);
        }
    }

    /** !!!OVERRIDE!!!
    * @dev Adds single address to whitelist.
    * @param _beneficiary Address to be added to the whitelist
    */
    function addToWhitelist(address _beneficiary) external onlyManager {
        whitelist[_beneficiary] = true;
    }

    /** !!!OVERRIDE!!!
    * @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing.
    * @param _beneficiaries Addresses to be added to the whitelist
    */
    function addManyToWhitelist(address[] _beneficiaries) external onlyManager {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    /** !!!OVERRIDE!!!
    * @dev Removes single address from whitelist.
    * @param _beneficiary Address to be removed to the whitelist
    */
    function removeFromWhitelist(address _beneficiary) external onlyManager {
        whitelist[_beneficiary] = false;
    }

    /** !!!OVERRIDE!!!
    * @dev called by the manager to pause, triggers stopped state
    */
    function pause() public onlyManager whenNotPaused onlyWhileOpen {
        paused = true;
        emit Pause();
    }

    /** !!!OVERRIDE!!!
    * @dev called by the manager to unpause, returns to normal state
    */
    function unpause() public onlyManager whenPaused {
        paused = false;
        emit Unpause();
    }

    /**
    * @dev onlyManager allows tokens to be tradeable after the 1st crowdsale round - does not finalize crowdsale in the traditional manner
    * purposely does not call super.finalize to avoid this line: require(hasClosed());
    */
    function finalize() public onlyManager {
        require(!isFinalized);
        if(crowdsaleRound == 0) {
            Pausable(token).unpause();
        }

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    /**
    * @dev transfer token ownership to new Crowdsale in the future. Note: contract Ownable already checks for address(0)
    * @param _newIco address of the new Crowdsale
    */
    function transferTokenOwnership(address _newIco) public onlyManager onlyIsFinalized {
        Ownable(token).transferOwnership(_newIco); // this will emit OwnershipTransferred event from contract Ownable
        disable();
    }

    /**
    * @dev onlyManager disable crowdsale permanently
    */
    function disable() public onlyManager onlyIsFinalized {
        disabled = true;
    }

    /**
    * @dev calculates if the investment is at least 5000 CHF per the current assigned rate
    */
    function isMinInvestment(uint256 _wei) public view returns (bool) {
        uint256 activeRate = ethPriceIndex[currentPriceIndex];
        // // Check for potential overflow before doing the precise calculation
        uint256 checkOverflow = (min_contribution_chf / activeRate).mul(1e18);
        // // calculate the minimal contribution in wei
        uint256 minContributionInWei = (min_contribution_chf / activeRate) * 1e18;
        return (_wei >= minContributionInWei);
    }

    /*** INTERNAL/PRIVATE FUNCTIONS ***/

    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen whenNotPaused {
        require(!capReached(), "cap has been (b)reached");
        require(isMinInvestment(_weiAmount), "is not min investment");
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        tokensMinted = tokensMinted.add(_tokenAmount);
        // respect the token cap
        require(tokensMinted <= cap, "tokensMinted > cap");
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 activeRate = tokenPriceIndex[currentPriceIndex];
        require(activeRate > 0);
        return _weiAmount.mul(activeRate).div(10**PRECISION);
    }
}
