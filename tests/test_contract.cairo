use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait};

use synthetix_staking::interfaces::istaking_rewards::{IStakingRewardsDispatcher, IStakingRewardsDispatcherTrait};

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

// const ONE_E18: u256 = u256 { low: 1000000000000000000_u128, high: 0_u128 };
const ONE_E18: u256 = 1000000000000000000_u256;


#[test]
fn test_increase_balance() {
    // let contract_address = deploy_contract("HelloStarknet");

    // let dispatcher = IHelloStarknetDispatcher { contract_address };

    // let balance_before = dispatcher.get_balance();
    // assert(balance_before == 0, 'Invalid balance');

    // dispatcher.increase_balance(42);

    // let balance_after = dispatcher.get_balance();
    // assert(balance_after == 42, 'Invalid balance');


    assert(1 == 1, 'wrong number');

    println!("{}", ONE_E18);
}
