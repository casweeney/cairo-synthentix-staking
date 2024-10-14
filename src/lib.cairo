use starknet::ContractAddress;

#[starknet::interface]
pub trait IStakingRewards<TContractState> {
    fn last_time_reward_applicable(self: @TContractState) -> u256;
    fn reward_per_token(self: @TContractState) -> u256;
    fn stake(ref self: TContractState, amount: u256);
    fn withdraw(ref self: TContractState, amount: u256);
    fn earned(self: @TContractState, account: ContractAddress) -> u256;
    fn get_reward(ref self: TContractState);
    fn set_rewards_duration(ref self: TContractState, duration: u256);
    fn notify_reward_amount(ref self: TContractState, amount: u256);
}

#[starknet::contract]
mod StakingRewards {
    use starknet::ContractAddress;
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, 
        Map, StoragePathEntry,
        MutableVecTrait, Vec, VecTrait
    };

    #[storage]
    struct Storage {
        staking_token: ContractAddress,
        rewards_token: ContractAddress,

        owner: ContractAddress,

        duration: u256,
        finish_at: u256,
        updated_at: u256,
        reward_rate: u256,
        reward_per_token_stored: u256,
        user_reward_per_token_paid: Map<ContractAddress, u256>,
        rewards: Map<ContractAddress, u256>,

        total_supply: u256,
        balance_of: Map<ContractAddress, u256>,
    }

    #[abi(embed_v0)]
    impl StakingRewardsImpl of super::IStakingRewards<ContractState> {
        
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn update_reward(ref self: ContractState, account: ContractAddress) {

        }

        fn min(self: @ContractState, x: u256, y: u256) -> u256 {

            1
        }
    }
}
