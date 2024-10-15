# Synthetix Staking Contract
This repo contains the implementation of Synthetix staking rewards contract in Cairo lang.

## Challenges
The Uni & Integration test for this contract wasn't completed because at the time of writing this contract, `get_block_timestamp()` function on Starknet was return `0` and most of the functions depended on that.

The test was done onchain, the contract was deployed on Starknet Sepolia and was tested via https://sepolia.voyager.online. Everything works fine as expected.

Staking token contract: 0x227e1a8c4ee85feccab767c584c0b46f5c4062e97a9219a91ec75c86ce0a840
Reward token contract: 0x702d2721fdcb98fae346bf1398e0702b27c8ccc97e75e632ff93653ece67253
Staking contract: 0x6c9df27d399ec8c9d417aaee3a591aea21e41d0d4661252007327cd3dee22a5

## Deployment
`deploy-r-t`: deploys the reward token using: `npm run deploy-r-t`
`deploy-s-t`: deploys the staking token using: `npm run deploy-s-t`
`deploy`: deploys the Staking contract using: `npm run deploy`