use starknet::{ContractAddress, get_block_timestamp};

use snforge_std::{declare, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address,};

use synthetix_staking::interfaces::istaking_rewards::{IStakingRewardsDispatcher, IStakingRewardsDispatcherTrait};
use synthetix_staking::interfaces::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};

fn deploy_token_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

fn deploy_staking_contract(name: ByteArray, staking_token: ContractAddress, reward_token: ContractAddress) -> ContractAddress {
    let owner: ContractAddress = starknet::contract_address_const::<0x123626789>();

    let mut constructor_calldata = ArrayTrait::new();
    constructor_calldata.append(owner.into());
    constructor_calldata.append(staking_token.into());
    constructor_calldata.append(reward_token.into());

    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    contract_address
}

#[test]
fn test_token_mint() {
    let staking_token_address = deploy_token_contract("StakingToken");
    let reward_token_address = deploy_token_contract("RewardToken");

    let staking_token = IERC20Dispatcher { contract_address: staking_token_address };
    let reward_token = IERC20Dispatcher { contract_address: reward_token_address };

    let receiver: ContractAddress = starknet::contract_address_const::<0x123626789>();

    let mint_amount: u256 = 10000_u256;
    staking_token.mint(receiver, mint_amount);
    reward_token.mint(receiver, mint_amount);

    assert!(staking_token.balance_of(receiver) == mint_amount, "wrong staking token balance");
    assert!(reward_token.balance_of(receiver) == mint_amount, "wrong reward token balance");
    assert!(staking_token.balance_of(receiver) > 0, "balance failed to increase");
    assert!(reward_token.balance_of(receiver) > 0, "balance didn't increase");
}

#[test]
fn test_staking_constructor() {
    let staking_token_address = deploy_token_contract("StakingToken");
    let reward_token_address = deploy_token_contract("RewardToken");
    let staking_contract_address = deploy_staking_contract("StakingRewards", staking_token_address, reward_token_address);

    let staking_contract = IStakingRewardsDispatcher { contract_address: staking_contract_address };

    let owner: ContractAddress = starknet::contract_address_const::<0x123626789>();


    assert!(staking_contract.owner() == owner, "wrong owner");
    assert!(staking_contract.staking_token() == staking_token_address, "wrong staking token address");
    assert!(staking_contract.rewards_token() == reward_token_address, "wrong reward token address");
}

#[test]
#[should_panic(expected: ("not authorized",))]
fn test_set_reward_duration_should_panic() {
    let staking_token_address = deploy_token_contract("StakingToken");
    let reward_token_address = deploy_token_contract("RewardToken");
    let staking_contract_address = deploy_staking_contract("StakingRewards", staking_token_address, reward_token_address);

    let staking_contract = IStakingRewardsDispatcher { contract_address: staking_contract_address };

    let duration: u256 = 1800_u256;

    staking_contract.set_rewards_duration(duration);
}

#[test]
fn test_reward_duration() {
    let staking_token_address = deploy_token_contract("StakingToken");
    let reward_token_address = deploy_token_contract("RewardToken");
    let staking_contract_address = deploy_staking_contract("StakingRewards", staking_token_address, reward_token_address);

    let staking_contract = IStakingRewardsDispatcher { contract_address: staking_contract_address };

    let owner: ContractAddress = starknet::contract_address_const::<0x123626789>();
    let block_timestamp: u256 = get_block_timestamp().try_into().unwrap();
    let duration: u256 = 1800_u256;

    println!("Finsh at {}", staking_contract.finish_at());
    println!("Duration {}", get_block_timestamp());

    // start_cheat_caller_address(staking_contract_address, owner);
    // staking_contract.set_rewards_duration(block_timestamp + duration);
    // stop_cheat_caller_address(staking_contract_address);


    // assert!(staking_contract.duration() == duration, "duration not properly set");
}