pragma solidity 0.4.21;

interface TokenCtrct {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

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

/**
 * @title Team and Advisors Token Allocation contract
 */

contract TeamAndAdvisorsAllocation is Ownable {
    using SafeMath for uint;

    uint256 public unlockedAt;
    uint256 public canSelfDestruct;
    uint256 public tokensCreated;
    uint256 public allocatedTokens;
    uint256 private totalTeamAndAdvisorsAllocation = 38763636e18; // 38 mm

    mapping (address => uint256) public teamAndAdvisorsAllocations;

    TokenCtrct public token;

    /**
     * @dev constructor function that sets owner and token for the TeamAndAdvisorsAllocation contract
     * @param _token Token contract address for TokennToken
     */
    function TeamAndAdvisorsAllocation(address _token) public {
        token = TokenCtrct(_token);
        unlockedAt = now.add(182 days);
        canSelfDestruct = now.add(365 days);
    }

    /**
     * @dev Adds founders' token allocation
     * @param teamOrAdvisorsAddress Address of a founder
     * @param allocationValue Number of tokens allocated to a founder
     * @return true if address is correctly added
     */
    function addTeamAndAdvisorsAllocation(address teamOrAdvisorsAddress, uint256 allocationValue)
    external
    onlyOwner
    returns(bool)
    {
        assert(teamAndAdvisorsAllocations[teamOrAdvisorsAddress] == 0); // can only add once.

        allocatedTokens = allocatedTokens.add(allocationValue);
        require(allocatedTokens <= totalTeamAndAdvisorsAllocation);

        teamAndAdvisorsAllocations[teamOrAdvisorsAddress] = allocationValue;
        return true;
    }

    /**
     * @dev Allow company to unlock allocated tokens by transferring them whitelisted addresses.
     * Need to be called by each address
     */
    function unlock() external {
        assert(now >= unlockedAt);

        // During first unlock attempt fetch total number of locked tokens.
        if (tokensCreated == 0) {
            tokensCreated = token.balanceOf(address(this));
        }

        uint256 transferAllocation = teamAndAdvisorsAllocations[msg.sender];
        teamAndAdvisorsAllocations[msg.sender] = 0;

        // Will fail if allocation (and therefore toTransfer) is 0.
        require(token.transfer(msg.sender, transferAllocation));
    }

    /**
     * @dev allow for selfdestruct possibility and sending funds to owner
     */
    function kill() public onlyOwner {
        assert(now >= canSelfDestruct);
        uint256 balance = token.balanceOf(address(this));

        if (balance > 0) {
            token.transfer(owner, balance);
        }

        selfdestruct(owner);
    }
}
