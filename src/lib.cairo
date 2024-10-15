pub mod interfaces;

#[starknet::contract]
mod StakingRewards {
    use core::num::traits::Zero;
    use synthetix_staking::interfaces::istaking_rewards::IStakingRewards;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address, get_contract_address};
    use core::starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, 
        Map, StoragePathEntry
    };
    use synthetix_staking::interfaces::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};

    const ONE_E18: u256 = 1000000000000000000_u256;

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
    impl StakingRewardsImpl of IStakingRewards<ContractState> {
        fn last_time_reward_applicable(self: @ContractState) -> u256 {
            let block_timestamp: u256 = get_block_timestamp().try_into().unwrap();

            self.min(self.finish_at.read(), block_timestamp)
        }

        fn reward_per_token(self: @ContractState) -> u256 {
            if self.total_supply.read() == 0 {
                self.reward_per_token_stored.read()
            } else {
                self.reward_per_token_stored.read() + (self.reward_rate.read() * (self.last_time_reward_applicable() - self.updated_at.read()) * ONE_E18 ) / self.total_supply.read()
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
            ((self.balance_of.entry(account).read() * (self.reward_per_token() - self.user_reward_per_token_paid.entry(account).read())) / ONE_E18) + self.rewards.entry(account).read()

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
            let block_timestamp: u256 = get_block_timestamp().try_into().unwrap();
            assert!(self.finish_at.read() < block_timestamp, "reward duration not finished");

            self.duration.write(duration);
        }

        fn notify_reward_amount(ref self: ContractState, amount: u256) {
            let block_timestamp: u256 = get_block_timestamp().try_into().unwrap();

            if block_timestamp >= self.finish_at.read() {
                self.reward_rate.write(amount / self.duration.read())
            } else {
                let remaining_rewards = (self.finish_at.read() - block_timestamp) * self.reward_rate.read();

                self.reward_rate.write((amount + remaining_rewards) / self.duration.read());
            }

            let rewards_token = IERC20Dispatcher { contract_address: self.rewards_token.read() };

            assert!(self.reward_rate.read() > 0, "reward rate = 0");
            assert!(self.reward_rate.read() * self.duration.read() <= rewards_token.balance_of(get_contract_address()), "reward amount > balance");

            self.finish_at.write(get_block_timestamp().try_into().unwrap() + self.duration.read());
            self.updated_at.write(get_block_timestamp().try_into().unwrap());
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
