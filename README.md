# Synthetix Staking Contract
This repo contains the implementation of Synthetix staking rewards contract in Cairo lang.

## Challenges
The Uni & Integration test for this contract wasn't completed because at the time of writing this contract, `get_block_timestamp()` function on Starknet was return `0` and most of the functions depended on that.

The test was done onchain, the contract was deployed on Starknet Sepolia @: and was tested via starkscan.io.

