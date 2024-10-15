use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait};

use synthetix_staking::interfaces::istaking_rewards::{IStakingRewardsDispatcher, IStakingRewardsDispatcherTrait};
use synthetix_staking::interfaces::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};

fn deploy_token_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

fn deploy_staking_contract(name: ByteArray, staking_token: ContractAddress, reward_token: ContractAddress) -> ContractAddress {
    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(staking_token.into());
    constructor_calldata.append(reward_token.into());

    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    contract_address
}

#[test]
fn test_token_mint() {
    let staking_token_contract = deploy_token_contract("StakingToken");
    let reward_token_contract = deploy_token_contract("RewardToken");
    let staking_contract = deploy_staking_contract("StakingRewards", staking_token_contract, reward_token_contract);

    let staking_token = IERC20Dispatcher { contract_address: staking_token_contract };
    let reward_token = IERC20Dispatcher { contract_address: reward_token_contract };

    let receiver: ContractAddress = starknet::contract_address_const::<0x123626789>();

    let mint_amount: u256 = 10000_u256;
    staking_token.mint(receiver, mint_amount);
    reward_token.mint(receiver, mint_amount);

    assert!(staking_token.balance_of(receiver) == mint_amount, "wrong staking token balance");
    assert!(reward_token.balance_of(receiver) == mint_amount, "wrong reward token balance");
    assert!(staking_token.balance_of(receiver) > 0, "balance failed to increase");
    assert!(reward_token.balance_of(receiver) > 0, "balance didn't increase");
}
