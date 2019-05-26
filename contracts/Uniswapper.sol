pragma solidity 0.4.21;

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

interface TokenContract {
    function pause() public;
    function unpause() public;
    function mint(address _to, uint256 _amount) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function getTotalSupply() public view returns(uint);
    function finishMinting() public returns (bool);
    function approve(address spender, uint tokens) public returns (bool success);
}
interface Exchange {
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}

// File: contracts/Uniswapper.sol

/**
 * @title Uniswapper contract
 */

contract Uniswapper is Ownable {
    using SafeMath for uint;

    uint256 public unlockedAt;
    uint256 public canSelfDestruct;
    uint256 public liquidityMinted;
    uint256 public rate;
    uint256 public tokenSent;
    uint256 public ethSent;
    uint256 public ethRemoved;
    uint256 public tokensRemoved;

    TokenContract public token;
    Exchange   public exchange;

    bool public locked;
    bool public unlocked;

    /**
     * @dev constructor function that sets token and exchange addresses for the Uniswapper contract
     * @param _token Token contract address for TokenToken
     * @param _exchange UniSwap exchange contract address created manually before for crowdSale token
     */
    function Uniswapper(address _token, address _exchange, uint _rate) public {
        token = TokenContract(_token);
        exchange = Exchange(_exchange);
        unlockedAt = now.add(1 hours);
        canSelfDestruct = now.add(500 days);
        rate = _rate;
    }

    function lock() external {
        require(locked == false);
        require(token.balanceOf(address(this)) > 0);
        locked = true;

        tokenSent = token.balanceOf(address(this)) / rate;
        ethSent = address(this).balance;
        token.approve(address(exchange), tokenSent);
        liquidityMinted = exchange.addLiquidity.value(ethSent)(0, tokenSent, now + 1 hours);
    }

    /**
     * @dev Allow owner to send liquidity tokens to UniSwap exchange after retention period.
     */
    function unlock() public onlyOwner {
        assert(now >= unlockedAt);
        assert(unlocked == false);
        unlocked = true;
        (ethRemoved, tokensRemoved) = exchange.removeLiquidity(liquidityMinted, ethSent, tokenSent, now + 1 hours);
        owner.transfer(ethRemoved);
        token.transfer(owner, tokensRemoved);
    }

    /**
     * @dev allow for selfdestruct possibility and sending funds to owner
     */
    function kill() public onlyOwner {
        assert(now >= canSelfDestruct);
        uint256 balance = token.balanceOf(this);

        if (balance > 0) {
            token.transfer(owner, balance);
        }

        selfdestruct(owner);
    }

    function() payable public {}

}
