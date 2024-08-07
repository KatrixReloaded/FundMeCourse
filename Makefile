-include .env

build:; forge build

deploy-sepolia:
	forge script script/FundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --account sepoliaKey --sender 0xc71a9057fA590213C530caaaFA78230C8A20ece4 --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

# check out foundry fund me course repo's Makefile for future use