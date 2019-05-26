pragma solidity 0.4.21;

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
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract TokenExchange {

    using SafeMath for *;

    TokenContract public token;
    uint public totalSupply;
    mapping (address => uint) _balances;
    uint public decimals;
    bytes32 public name;
    bytes32 public symbol;

    event AddLiquidity(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);
    event RemoveLiquidity(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function setup(address token_addr) public {
        token = TokenContract(token_addr);
        name = 0x556e697377617020563100000000000000000000000000000000000000000000;
        symbol = 0x554e492d56310000000000000000000000000000000000000000000000000000;
        decimals = 18;
    }

    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) public payable returns (uint256) {
        require(deadline > block.timestamp && max_tokens > 0 && msg.value > 0);
        uint256 total_liquidity = totalSupply;
        uint256 token_amount;

        if (total_liquidity > 0) {
            require(min_liquidity > 0);
            uint256 eth_reserve = address(this).balance.sub(msg.value);
            uint256 token_reserve = token.balanceOf(address(this));
            token_amount = (msg.value.mul(token_reserve) / eth_reserve).add(1);
            uint256 liquidity_minted = msg.value.mul(total_liquidity) / eth_reserve;
            require(max_tokens >= token_amount && liquidity_minted >= min_liquidity);
            _balances[msg.sender] = _balances[msg.sender].add(liquidity_minted);
            totalSupply = total_liquidity.add(liquidity_minted);
            require(token.transferFrom(msg.sender, address(this), token_amount));
            emit AddLiquidity(msg.sender, msg.value, token_amount);
            emit Transfer(address(0), msg.sender, liquidity_minted);
            return liquidity_minted;

        } else {
            require(address(token) != address(0) && msg.value >= 1000000000);
            token_amount = max_tokens;
            uint256 initial_liquidity = address(this).balance;
            totalSupply = initial_liquidity;
            _balances[msg.sender] = initial_liquidity;
            require(token.transferFrom(msg.sender, address(this), token_amount));
            emit AddLiquidity(msg.sender, msg.value, token_amount);
            return initial_liquidity;
        }
    }

    function removeLiquidity(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) public returns (uint256, uint256) {
        require(amount > 0 && deadline > block.timestamp && min_eth > 0 && min_tokens > 0);
        uint256 total_liquidity = totalSupply;
        require(total_liquidity > 0);
        uint256 token_reserve = token.balanceOf(address(this));
        uint256 eth_amount = amount.mul(address(this).balance) / total_liquidity;
        uint256 token_amount = amount.mul(token_reserve) / total_liquidity;
        require(eth_amount >= min_eth && token_amount >= min_tokens);

        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        totalSupply = total_liquidity.sub(amount);
        msg.sender.transfer(eth_amount);
        require(token.transfer(msg.sender, token_amount));
        emit RemoveLiquidity(msg.sender, eth_amount, token_amount);
        return (eth_amount, token_amount);
    }
}
