# Tokenn Crowdsale Smart Contract
 
This crowdsale smart contract builds on (forked) triple-audided crowdsale smart contract development by Odem. Additions include:
* The token's Uniswap market is capitalized with tokens and ETH on crowdsale finalization and liquidity tokens non-vested;
* Updates and housekeeping of out of date code

## Smart contracts
 
* Airdropper
* Whitelist
* TokenSale
* TOKEN
* Locked

## Addresses and wallets

Required wallets include
* _reward
* _wallet
* Airdropper owner
* Whitelist owner
* TokenSale owner
* TOKEN owner (It is owned by TokenSale)
* Locked

## Parameters

### Starting rate:

tokens per wei rate

### Timings

* Deploy date
* Crowdsale start
* Crowdsale end
* Finalization date
* Non-vest lock in time (days after deployment)
* Non-vest kill before (days after deployment)

### Token allocations

* Presale
* Crowdsale
* Bounties
* Team 
* Other
* Uniswap (pooled ETH depends on tokens per wei rate)
* TOTAL

# Contracts

## Airdropper

An airdropper contract completes all individual transfers within one combined transaction reducing fees associated with the distribution. Airdropper never holds tokens. Instead it calls ERC20's transferFrom to transfer tokens directly from the reward wallet to the recipients. Recipients can see that their tokens came directly from this address, so they can verify that they received their rewards in good order. The address is recorded in the TOKEN ICO repository. The contract can be tested on the main network without interfering with the allocation of reward TOKEN, and without the need to deploy a new instance after testing.

Airdropper also has a method to self-destruct, which is called as soon as tokens have been distributed to all recipients. This prevents it from being used as an attack vector in any future zero-day exploits, and takes some load off the Ethereum network (it's important to be a good neighbour).

## Whitelist
 
The whitelist contract will contain the (mutable) addresses of backers who are allowed to buy tokens during the tokensale period. Whitelisted account addresses are stored in the contract instance.

### Features

Ownable - The owner if the Whitelist instance can transfer the ownership at any time to any other account.

Mutability - Addresses can be added to or removed from a Whitelist instance by its owner at any time.

Owner - Only the Whitelist instance’s owner is allowed to add/remove addresses to/from the whitelist. Initially, this will be the account who deployed the Whitelist instance, but ownership can be transferred later by the current owner to any other account. The owner does not need to be the same as of the TokenSale instance.

Lifecycle - Whitelist’s behavior is invariant with respect to time.

Constraints - Only the owner is allowed to add or remove addresses. There are no time related restrictions on adding or removing entries. The TokenSale instance will read this set only during the crowdsale period.

## TokenSale
 
When TokenSale is deployed it creates a new Token instance, thus becoming its owner. 

The following token related constants are defined:

Amount of tokens minted in total | TOTAL_TOKENS_SUPPLY | E.g. 50 million (50000000e18 (~ 50M ×10 18  tokens)
Amount of tokens minted in favor of the _reward account on crowdsale finalization | REWARD_SHARE (old name BOUNTY_REWARD_SHARE) | E.g. 4.5 million (4500000e18 (~ 4.5M ×10 18  tokens))
Amount of tokens minted in favor of the _wallet account on crowdsale finalization | VESTED_TEAM_ADVISORS_ SHARE
Amount of tokens minted in favor of the _wallet account on crowdsale finalization | COMPANY_SHARE
Amount of tokens minted in favor of Locked instance on crowdsale finalization | LOCKED (formerly called NON_VESTED_TEAM_ADVISORS_SHARE) | E.g. 37.5 million (37500000e18 (~ 37.5M ×10 18  tokens))
Maximum total amount of tokens minted in favor of PreSale buyers. | PRE_CROWDSALE_CAP | E.g. 0.5million (500000e18 (~ 0.5M ×10 18  tokens))
Maximum total amount of tokens bought by contributors during presale | PUBLIC_CROWDSALE_CAP | 7.5million (7500000e18 (~ 7.5M ×10 18  tokens))
Maximum total amount of tokens minted during pre-sale and crowdsale | TOTAL_TOKENS_FOR_CROWDSALE =  PRE_CROWDSALE_CAP  +  PUBLIC_CROWDSALE_CAP | E.g. 8million ( 8000000e18 (~  8M×10 18  tokens))

Total supply
 
TOTAL_TOKENS_SUPPLY  == token.totalSupply
TOTAL_TOKENS_FOR_CROWDSALE  = PRE_CROWDSALE_CAP + PUBLIC_CROWDSALE_CAP.
TOTAL_TOKENS_FOR_CROWDSALE  <=  TOTAL_TOKENS_SUPPLY
TOTAL_TOKENS_SUPPLY  >=  REWARD_SHARE +  VESTED_TEAM_ADVISORS_SHARE +  NON_VESTED_TEAM_ADVISORS_SHARE +  COMPANY_SHARE +  TOTAL_TOKENS_FOR_CROWDSALE

### Features

Ownable - The owner of an TokenSale instance can transfer the ownership at any time to any other account.

Pausable - During the crowdsale (i.e. from start till end) the sale of tokens to investors can be halted or continued by the TokenSale instance’s owner. Pausing in other periods is possible but without any effects.

Early buyers - During the crowdsale start, the amount of tokens a single investor can buy is capped (see Constants:  PERSONAL_CAP) E.g. PERSONAL_CAP = 2.5million (e.g. 2500000e18 (~ 2.5M ×10 18  tokens)). This is independent of if the contributor already received tokens due to presale minting.

Total amount - The total amount of tokens that can be bought during crowdsale is capped (see Constants: TOTAL_TOKENS_FOR_CROWDSALE). If the last contributor tries to buy more tokens than are available, he/she will get the remaining ones (with respect to the cap) and his/her address along with the overpaid amount of ether will be stored for later refund. These refunds will be paid out manually.

Finalizable - After the end of crowdsale, the TokenSale instance has to be finalized to enable the free trade/transfer of tokens. This can be done solely by the owner, only after the crowdsale has ended, and only once.

### Accounts/Roles

Owner - the owner of an TokenSale instance is the account who created/deployed it. The owner can:
* transfer ownership at any time to any other account
* mint  tokens  for  the  benefit  of  any  account  as  long as a) the crowdsale has not started yet, and b) the  total  will  not  exceed  the  presale  cap  (see  Constants:  PRE_CROWDSALE_CAP)
* adjust the (tokens per wei) rate at any time to any non-zero value.
* set the address of a deployed Locked instance
* finalize the contract instance after the crowdsale has ended (and only if it wasn’t finalized already)
 
## Wallet

Crowdsale funds - This wallet (usually a multisig) will hold the crowdsale funds received during the crowdsale. The wallet address must be given when creating a TokenSale instance and cannot be changed afterwards.

Tokens - When the crowdsale is finalized, NON_VESTED_TEAM_ADVISORS_SHARE, and COMPANY_SHARE will be minted for the benefit of the _wallet account.

## Reward Wallet

When the crowdsale is finalized, a fixed amount of tokens from the rewards campaign (see Constants: sol: REWARD_SHARE) will be minted for the benefit of this account.

## Token

TOKEN is an ERC20 compliant token contract. TokenSale will become the TOKEN instance’s owner, therefore, the following sections refer to an TOKEN instance created and owned by an existing TokenSale instance. Transferring the ownership of the TokenSale instance doesn’t affect the ownership of its assigned TOKEN instance (it will remain the crowdsale contract instance).

Lifecycle
During initialization, i.e. deployment, of a TokenSale instance, a paused TOKEN instance will be created, and the following state variables will be stored:
* start time of crowdsale period
* end time of crowdsale period
* wallet address
* reward Wallet addresses
* address of prior to this created Whitelist instance
* address of newly created TOKEN instance
* (tokens per wei) rate
* address of newly created Uniswap Market

### Features

Ownable - The TOKEN contract is Ownable, thus exposing a method to its owner for transferring the ownership to a new address. But since TokenSale is its owner and doesn’t use this feature, it will stay its TOKEN’s owner forever.
Pausable - The trade of tokens, i.e. transfer from one account to another, of tokens can be halted and continued by its owner (see Lifecycle).

Mintable - The TOKEN instance’s owner is able to mint some tokens, i.e. create new tokens and increase any account’s token balance.

### Accounts/Roles

Owner - The TokenSale instance will own the TOKEN instance.

Token holders - The TOKEN contract by itself does not impose any restrictions on which accounts can hold tokens. But as the contract instance is owned by a TokenSale instance, there are some limitations on how to get tokens:
1.  Being a presale buyer and receiving tokens from the instance owner before the crowdsale period starts.
2.  Becoming whitelisted by the Whitelist instance’s owner, thus being allowed to purchase tokens during the crowdsale period.
3.  The predefined wallet and reward accounts will get their allocated tokens at the end of crowdsale period.
4.  Tokens allocated by the Locked instance owner, which are available after the retention period has ended.
5.  Being the receiver of a freely tradable ERC20 compliant token transfer after the crowdsale has ended.

Lifecycle

Paused
When an TOKEN instance is created its state will be set paused, therefore, token minting is possible but trade/transfer is not.

Unpaused
After the crowdsale period has ended, the TokenSale instance has to be finalized manually (or by any off-chain automatism). The TokenSale instance will unpause its TOKEN instance making tokens transferable from token holders to any Ethereum accounts. TokenSale ensures that minting of tokens is not possible anymore.

Constraints
The TOKEN by itself doesn’t impose any restrictions on when it is paused/unpaused or beneficiaries of minted or transferred tokens as these are controlled by the owning TokenSale instance.

Pause/Unpause
The pause/unpause state can be changed by the owning TokenSale instance only.

Minting
The amount and receivers of minted tokens is controlled by the owning TokenSale instance only.

Total Supply
The  maximum  total  supply  of  tokens  is  controlled  by  the  owning  TokenSale  instance’s  minting restrictions  and  won’t  exceed  TOTAL_TOKENS_FOR_CROWDSALE (see  Crowdsale  Constants)  before crowdsale finalization. After  crowdsale  finalization  the  total  amount  of  tokens  is  fixed  to  TOTAL_TOKENS_SUPPLY  (see Crowdsale Constants).

End of Crowdsale
The crowdsale ends if either the crowdsale period elapsed or all available tokens were purchased. In the latter case the crowdsale will end before its predefined end time.

If the total supplied tokens is below a predefined cap (see Constants: TOTAL_TOKENS_SUPPLY), the remaining tokens (i.e. the difference) will be minted for _wallet addresses (see above). The TOKEN instance will be unpaused, so that tokens become free tradable/transferable.

## Locked
 
A Locked instance has to be deployed prior to finalization of crowdsale.  It receives a fixed share of TOKEN (see TokenSale Constants:  LOCKED), thus becoming a token holder. It allows the distribution of its tokens. The assigned owners can transfer these to their own accounts as soon as the retention period has expired.

### Features

Ownable - The Locked contract is Ownable, thus exposing a method to its owner for transferring the ownership to a new address.

Retention period - The withdrawal of tokens is blocked for 365 days after the finalization of the crowdsale. During the first 365 days after contract instance creation the token share of team members and advisors can be set, but no one will be able to transfer them to their own account.

Unlock Period
After  the  retention  period  has  ended,  team  members  and  advisors  are  allowed  to  unlock  their  token share, thus triggering the transfer to their own accounts.

Destruction - At least 500 days after finalization of the crowdsale, this contract instance can be destroyed by the contract’s owner. All remaining tokens of this contract instance will be transferred to the owner’s account. Team members and advisors who have not unlocked their tokens share will lose them.

### Accounts/Roles

Owner - The owner can assign token shares to team members and advisors. The owner can destroy it after the destruction period.

Team Member or Advisor -  A number of tokens can be assigned to these accounts. After the expiration of the initial retention period, they can unlock (i.e. withdraw) their share in tokens, which will be transferred to their accounts.

### Constraints

Allocation - The amount of allocated tokens can be set for every team member or advisor account only once. The total amount of allocated tokens must not exceed the predefined cap (see Constants).

Total Supply - The  predefined cap of allocated tokens must not be greater than the amount of initially minted tokens LOCKED, otherwise it would be possible to allocate more tokens than available, i.e.  some team members won’t be able to unlock their share.

# Contracts Deployment Order
 
The contracts must be deployed in the following order:

* Whitelist has to be deployed manually first. Its address is needed in the next step. Before deploying TokenSale it must be assured that the deployed Whitelist instance is fully functional, i.e.  the owner can add and remove addresses producing Whitelisted status results as expected. The constructor of TokenSale will accept any address as _whitelist parameter, but the  actual  usage  of  Whitelist (that  is  to  check  for  if  an  address  was  whitelisted) doesn’t  happen before the crowdsale period starts.
* TokenSale  has  to  be  deployed  manually  after  Whitelist. The following cannot be changed after deployment
_startTime
_endTime
_whitelist
_wallet
_rewardWallet
* TOKEN is deployed after TokenSale with TokenSale its owner. One can call the public getter function token() of the crowdsale instance to determine the token’s address.
* Airdropper requires address and decimals from TOKEN. Allow function is called by owner once Airdropper address created.
* Locked contracts must be deployed manually before the crowdsale gets finalized. Locked is loosely coupled to the other contracts. It is not essential for the crowdsale or token trading. Any time before crowdsale finalization the crowdsale’s contract owner can decide to replace it by another implementation or even to set a regular user account becoming the crowdsale instance’s Locked address. The contract will start a 365 day retention period on initialization therefore they should be deployed at the last possible moment after the crowdsale has ended and before calling finalize of the crowdsale contract instance.

# Test Cases
## Test: Deployment of TOKEN
Rationale: The token contract will be deployed automatically by TOKENpresale on initialization.
Expected behavior:
•       Success.
•       Deployer account (crowdsale contract) becomes token owner.
•       The global state variables name, symbol, decimals are correctly set.
## Test: Deployment of TeamAndAvisorsAllocation
Rationale: Contract TeamAndAvisorsAllocation must be deployable.

Expected behavior:
•       Success.
•       Deployer account becomes contract instance owner.
•       The state variable TOKEN is set to the constructor parameters value token.
•       The state variable unlockedAt is correctly calculated as now + 365 days (= now + 365 * 24 * 60 * 60).
•       The state variable canSelfDestruct is correctly calculated as now + 500 days (= now + 500 * 24 * 60 * 60).
## Test: Constants sanity check
Rationale: The constants totalLocked constitutes a cap on the amount of tokens that can be assigned by team members. It should not be greater than the amount of tokens that get minted for this contract on crowdsale finalization (TOKENpresale.VESTED_TEAM_ADVISORS_SHARE), otherwise some team members won’t be able to unlock their share.

Expected behavior:
•       The constraint is fulfilled.
## Test: Owner adds a team member’s share
Rationale: The team member’s share gets saved.

Expected behavior:
•       Success.
•       The total number of allocated tokens is increased by the share amount.
•       The team member’s share is correctly added to the Lockeds.
## Test: Owner changes a team member’s share before it was unlocked
Rationale: The share of a team member (an account) can be set only once until it gets unlocked and thus withdrawn by the team member.

Expected behavior:
•       Failure / transaction reversal.
## Test: Owner adds a team member’s share so that the total cap is exceeded
Rationale: The total amount of allocated tokens totalLocked.

Expected behavior:
•       Failure / transaction reversal.
## Test: A third party (non-owner) adds an allocation
Rationale: Only the owner should be able to add allocations.

Expected behavior:
•       Failure / transaction reversal.
## Test: Team member unlocks his/her share within retention period
Rationale: Nobody should be able to unlock his/her share during the first 365 days after contract deployment.

Expected behavior:
•       Failure / transaction reversal.
##Test: Team member unlocks his/her share after retention period
Rationale: Team members get their token share by unlocking it, so that it gets credited to their token balance.

Expected behavior:
•       Success.
•       The total amount of tokens possessed by the contract is saved to tokensCreated if this was the first call to unlock() by anyone.
•       Token balance of Locked contract is reduced by the team member’s share.
•       Token balance of team member is increased by his/her share.
•       The allocation of the team member is set to zero.
## Test: Team member unlocks his/her share after contract was killed
Rationale: After killing the contract no unlocking of token share should be possible.

Expected behavior:
•       Failure / transaction reversal.
## Test: A third party (non-team-member) unlocks
Rationale: Non-team-members have no token share, i.e. their allocation is zero. If they attempt to unlock they’ll waste gas.
## Test: Owner kills contract within the first 500 days after deployment
Rationale: The Locked contract instance has to be accessible for at least 500 days.

Expected behavior:
•       Failure / transaction reversal.
•       Success.
•       The total amount of tokens possessed by the contract is saved to tokensCreated if this was  the first call to unlock() by anyone.
•       An amount of zero tokens will be transferred / added to the caller’s balance.
## Test: Owner kills contract 500 days or more after deployment
Rationale: Destroying the Locked contract will make all team members lose their not-yet unlocked token share.

Expected behavior:
•       All remaining tokens of the contract (including those which weren’t unlocked by team members) get transferred to the owner, thus increasing his/her token balance.
•       Token balance of Locked instance is zero. • The contract gets destroyed (code data of account is set to 0x0).

## Test Environments

The TOKEN ICO contracts were tested on different networks.
1.     Deployment on the Rinkeby test network.

•       The testing was carried out by manually calling the contract functions via MyEtherWallet and MetaMask from different accounts.
•       Analysis of transaction history and contract state were done via MyEtherWallet and Etherscan.
2.     Deployment on a local machine.
·       Automated tests for the Truffle (v4.0.5) test framework were written and executed on a local Ganache-CLI (v6.0.3) instance.
3.     Deployment on a local test network.
·       The above mentioned automated tests and some additional manual tests were carried out on a Parity (v1.8.6) development network.
·       Analysis of transaction history and contract state was done via Parity’s frontend.
