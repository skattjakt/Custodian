#https://github.com/Cyfrin/foundry-nft-cu/blob/main/Makefile
#https://docs.metamask.io/wallet/how-to/run-devnet/
-include .env

MAKEFLAGS += --always-make


LOCALNET_ANVIL_SEEDPHRASE := need tail thank cheap scrub claw cheap spare year express surge math
LOCALNET_ANVIL_KEY := 0xc830ee75f970419b613de636ae87bb18ddfc1166d747fe4737bf403020c9cb99

all : clean update build test format
clean :; forge clean
update :; forge update
build :; forge build
test :; forge test
format :; forge fmt

start-anvil-net :; make -j 2 anvil deploy-anvil

anvil :; anvil --fork-url ${MAINNET_FORK_URL} --block-time 10 --chain-id 31337 -m '$(LOCALNET_ANVIL_SEEDPHRASE)'

deploy-anvil :; 
	sleep 10
	@forge script script/Deploy.s.sol --rpc-url http://localhost:8545  --private-key $(LOCALNET_ANVIL_KEY) --broadcast 