## Installation

`git clone --recurse-submodules <repo-URL>`
`git submodule update --init --recursive`

```sh
forge install
```

### Running tests locally

1. `forge test -vv`
2. `forge test --match-path test/EntityERC5643Test.t.sol -vv`

`source .env`
`forge test --via-ir --fork-url $SEPOLIA_RPC_URL --match-path test/EntityTest.t.sol -vv`
`forge script script/Project.s.sol:MyScript --via-ir --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vv`
