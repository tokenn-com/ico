pragma solidity 0.4.21;

interface TokenToken {
    function pause() public;
    function unpause() public;
    function mint(address _to, uint256 _amount) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function getTotalSupply() public view returns(uint);
    function finishMinting() public returns (bool);
}

interface Whitelist {
    function isWhitelisted(address _address) public view returns (bool);
}

interface Uniswapper {
    function lock() external;
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: zeppelin-solidity/contracts/crowdsale/TokenCrowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    // token contract to be set
    TokenToken public token;

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
        require(_startTime >= now);
        require(_endTime > _startTime);
        require(_rate > 0);

        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }


}

// File: zeppelin-solidity/contracts/crowdsale/FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super.finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function finalization() internal {}
}

// File: contracts/TokenCrowdsale.sol

/**
 * @title Token Crowdsale contract - crowdsale contract for the Token tokens.
 */

contract TokenCrowdsale is FinalizableCrowdsale, Pausable {
    uint256 constant public REWARD_SHARE =                   4500000e18;    // 4.5 mm
    uint256 constant public UNISWAPPER_SHARE =               37500000e18;   //  37.5 mm
    uint256 constant public PRE_CROWDSALE_CAP =              500000e18;     //  0.5 mm
    uint256 constant public PUBLIC_CROWDSALE_CAP =           7500000e18;    // 7.5 mm
    uint256 constant public TOTAL_TOKENS_FOR_CROWDSALE = PRE_CROWDSALE_CAP + PUBLIC_CROWDSALE_CAP;
    uint256 constant public TOTAL_TOKENS_SUPPLY =            50000000e18;   // 50 mm
    uint256 constant public PERSONAL_CAP =                   2500000e18;    //   2.5 mm

    address public rewardWallet;
    address public uniswapper;

    // remainderPurchaser and remainderTokens info saved in the contract
    // used for reference for contract owner to send refund if any to last purchaser after end of crowdsale
    address public remainderPurchaser;
    uint256 public remainderAmount;

    mapping (address => uint256) public trackBuyersPurchases;

    // external contracts
    Whitelist public whitelist;
    Uniswapper public uniswapperContract;

    event PrivateInvestorTokenPurchase(address indexed investor, uint256 tokensPurchased);
    event TokenRateChanged(uint256 previousRate, uint256 newRate);

    /**
     * @dev Contract constructor function
     * @param _startTime The timestamp of the beginning of the crowdsale
     * @param _endTime Timestamp when the crowdsale will finish
     * @param _whitelist contract containing the whitelisted addresses
     * @param _rate The token rate per ETH
     * @param _rewardWallet wallet that will hold tokens bounty and rewards campaign
     */
    function TokenCrowdsale
    (
        uint256 _startTime,
        uint256 _endTime,
        address _whitelist,
        uint256 _rate,
        address _rewardWallet
    )
    public
    FinalizableCrowdsale()
    Crowdsale(_startTime, _endTime, _rate, address(0))
    {

        require(_whitelist != address(0) && _rewardWallet != address(0));
        whitelist = Whitelist(_whitelist);
        rewardWallet = _rewardWallet;

    }

    function setTokenContractAddress(address _token) public onlyOwner {
        token = TokenToken(_token);
    }

    modifier whitelisted(address beneficiary) {
        require(whitelist.isWhitelisted(beneficiary));
        _;
    }

    /**
     * @dev change crowdsale rate
     * @param newRate Figure that corresponds to the new rate per token
     */
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate != 0);

        emit TokenRateChanged(rate, newRate);
        rate = newRate;
    }

    /**
     * @dev Mint tokens for pre crowdsale purchases before crowdsale starts
     * @param investorsAddress Purchaser's address
     * @param tokensPurchased Tokens purchased during pre crowdsale
     */
    function mintTokenForPreCrowdsale(address investorsAddress, uint256 tokensPurchased)
    external
    onlyOwner
    {
        require(now < startTime && investorsAddress != address(0));
        require(token.getTotalSupply().add(tokensPurchased) <= PRE_CROWDSALE_CAP);

        token.mint(investorsAddress, tokensPurchased);
        emit PrivateInvestorTokenPurchase(investorsAddress, tokensPurchased);
    }

    /**
     * @dev Set the address which should receive the vested team tokens share on finalization
     * @param _uniswapper address of team and uniswapper contract
     */
    function setUniswapperAddress(address _uniswapper) public onlyOwner {
        require(_uniswapper != address(0x0));
        uniswapper = Uniswapper(_uniswapper);
    }


    /**
     * @dev payable function that allow token purchases
     * @param beneficiary Address of the purchaser
     */
    function buyTokens(address beneficiary)
    public
    whenNotPaused
    whitelisted(beneficiary)
    payable
    {
        require(beneficiary != address(0));
        require(msg.sender == beneficiary);
        require(validPurchase() && token.getTotalSupply() < TOTAL_TOKENS_FOR_CROWDSALE);

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount.mul(rate);

        require(trackBuyersPurchases[msg.sender].add(tokens) <= PERSONAL_CAP);

        trackBuyersPurchases[beneficiary] = trackBuyersPurchases[beneficiary].add(tokens);

        //remainder logic
        if (token.getTotalSupply().add(tokens) > TOTAL_TOKENS_FOR_CROWDSALE) {
            tokens = TOTAL_TOKENS_FOR_CROWDSALE.sub(token.getTotalSupply());
            weiAmount = tokens.div(rate);

            // save info so as to refund purchaser after crowdsale's end
            remainderPurchaser = msg.sender;
            remainderAmount = msg.value.sub(weiAmount);
        }

        // update state
        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokens);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        if (token.getTotalSupply() == TOTAL_TOKENS_FOR_CROWDSALE) {
            return true;
        }

        return super.hasEnded();
    }

    /**
     * @dev finalizes crowdsale
     */
    function finalization() internal {
        // This must have been set manually prior to finalize().
        require(uniswapper != address(0x0));

        // final minting
        token.mint(uniswapper, UNISWAPPER_SHARE);
        token.mint(rewardWallet, REWARD_SHARE);

        if (TOTAL_TOKENS_SUPPLY > token.getTotalSupply()) {
            uint256 remainingTokens = TOTAL_TOKENS_SUPPLY.sub(token.getTotalSupply());

            token.mint(wallet, remainingTokens);
        }

        token.finishMinting();
        TokenToken(token).unpause();
        super.finalization();
        uniswapperContract.lock();

    }
}
