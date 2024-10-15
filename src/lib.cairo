use starknet::ContractAddress;

#[starknet::interface]
pub trait IERC20<TContractState> {
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn decimals(self: @TContractState) -> u8;

    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
}

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
    use core::num::traits::Zero;
    use super::IStakingRewards;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, 
        Map, StoragePathEntry
    };
    use super::{IERC20Dispatcher, IERC20DispatcherTrait};

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

    #[constructor]
    fn constructor(ref self: ContractState, staking_token: ContractAddress, reward_token: ContractAddress) {
        let caller = get_caller_address();
        self.owner.write(caller);
        self.staking_token.write(staking_token);
        self.rewards_token.write(reward_token);
    }

    #[abi(embed_v0)]
    impl StakingRewardsImpl of super::IStakingRewards<ContractState> {
        fn last_time_reward_applicable(self: @ContractState) -> u256 {
            let block_timestamp: u256 = get_block_timestamp().try_into().unwrap();

            self.min(self.finish_at.read(), block_timestamp)
        }

        fn reward_per_token(self: @ContractState) -> u256 {
            if self.total_supply.read() == 0 {
                self.reward_per_token_stored.read()
            } else {
                self.reward_per_token_stored.read() + (self.reward_rate.read() * (self.last_time_reward_applicable() - self.updated_at.read()) * (10 * 10 * 10) ) / self.total_supply.read()
            }
        }

        fn stake(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            let this_contract = get_contract_address();

            self.update_reward(caller);

            assert!(amount > 0, "amount = 0");
            let staking_token = IERC20Dispatcher { contract_address: self.staking_token.read() };
            let transfer = staking_token.transfer_from(caller, this_contract, amount);

            assert!(transfer, "transfer failed");

            let prev_stake = self.balance_of.entry(caller).read();
            self.balance_of.entry(caller).write(prev_stake + amount);

            let prev_supply = self.total_supply.read();
            self.total_supply.write(prev_supply + amount);
        }

        fn withdraw(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();

            self.update_reward(caller);

            assert!(amount > 0, "amount = 0");

            let prev_stake = self.balance_of.entry(caller).read();
            assert!(prev_stake >= amount, "insufficient stake balance");
            self.balance_of.entry(caller).write(prev_stake - amount);

            let prev_supply = self.total_supply.read();
            self.total_supply.write(prev_supply - amount);

            let staking_token = IERC20Dispatcher { contract_address: self.staking_token.read() };
            let transfer = staking_token.transfer(caller, amount);

            assert!(transfer, "transfer failed");
        }

        fn earned(self: @ContractState, account: ContractAddress) -> u256 {
            ((self.balance_of.entry(account).read() * (self.reward_per_token() - self.user_reward_per_token_paid.entry(account).read())) / (10 * 10 * 10)) + self.rewards.entry(account).read()

        }

        fn get_reward(ref self: ContractState) {
            let caller = get_caller_address();
            let reward = self.rewards.entry(caller).read();

            if reward > 0 {
                self.rewards.entry(caller).write(0);
                IERC20Dispatcher { contract_address: self.rewards_token.read() }.transfer(caller, reward);
            }
        }

        fn set_rewards_duration(ref self: ContractState, duration: u256) {

        }

        fn notify_reward_amount(ref self: ContractState, amount: u256) {

        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn update_reward(ref self: ContractState, account: ContractAddress) {
            self.reward_per_token_stored.write(self.reward_per_token());
            self.updated_at.write(self.last_time_reward_applicable());

            if account.is_non_zero() {
                self.rewards.entry(account).write(self.earned(account));
                self.user_reward_per_token_paid.entry(account).write(self.reward_per_token_stored.read());
            } 
        }

        fn min(self: @ContractState, x: u256, y: u256) -> u256 {
            if x <= y {
                x
            } else {
                y
            }
        }
    }
}
