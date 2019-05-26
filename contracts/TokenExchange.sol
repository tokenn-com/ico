pragma solidity 0.4.21;

contract TokenExchange {

    uint public a;

    function TokenExchange() public {
        a = 5;
    }

    function addLiquidity(uint min_liquidity, uint max_tokens, uint deadline) public payable returns(uint){
        uint initial_liquidity = msg.value;
        return initial_liquidity;
    }

    function removeLiquidity(uint amount, uint min_eth, uint min_tokens, uint deadline) public returns(uint, uint) {
        return (address(this).balance, min_tokens);
    }
}
