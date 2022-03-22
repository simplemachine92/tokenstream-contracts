# quadratic-sandwich-contracts

## Setup

```
git clone https://github.com/moonshotcollective/quadratic-sandwich-contracts.git

cd quadratic-sandwich-contracts

forge update
```

## Local Deploy
Run a local node, then,

Badge.sol:
```
forge create --rpc-url http://127.0.0.1:8545/ --constructor-args 0xb010ca9Be09C382A9f31b79493bb232bCC319f01 "Public Goods Voting" "PGV" "https://forgottenbots.mypinata.cloud/ipfs/QmZKUPeCSZSiz6MNVA6qDGb5yo9LDG3dQMVojK8HLbynu1" --private-key YourLocalPrivateKey src/Badge.sol:Badge
```

## Tests
```
forge test
```
