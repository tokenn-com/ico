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

interface TokenToken {
    function pause() public;
    function unpause() public;
    function mint(address _to, uint256 _amount) public returns (bool);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function getTotalSupply() public view returns(uint);
    function finishMinting() public returns (bool);
}
interface Exchange {
    function addLiquidity(uint min_liquidity, uint max_tokens, uint deadline) public payable returns (uint);
    function removeLiquidity(uint amount, uint min_eth, uint min_tokens, uint deadline) public returns(uint, uint);
}

// File: contracts/Uniswapper.sol

/**
 * @title Uniswapper contract
 */

contract Uniswapper is Ownable {
    using SafeMath for uint;

    uint256 public unlockedAt;
    uint256 public canSelfDestruct;
    uint256 public tokensCreated;
    uint256 public allocatedTokens;
    uint256 private UNISWAPPER_SHARE = 37500000e18; // 37.5 mm

    TokenToken public token;
    Exchange public exchange;

    /**
     * @dev constructor function that sets owner and token for the Uniswapper contract
     * @param _token Token contract address for TokenToken
     * @param _exchange UniSwap exchange contract address created manually before for crowdSale token
     */
    function Uniswapper(address _token, address _exchange) public {
        token = TokenToken(_token);
        exchange = Exchange(_exchange);
        unlockedAt = now.add(365 days);
        canSelfDestruct = now.add(500 days);
    }

    /**
     * @dev Allow owner to send liquidity tokens to UniSwap exchange after retention period.
     */
    function unlock() public onlyOwner {
        assert(now >= unlockedAt);

        //TODO: RETURNING LIQUIDITY HERE
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
}
