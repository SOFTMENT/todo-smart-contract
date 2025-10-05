-include .env                                # Silently include .env if present (won’t error if missing). Exposes env vars to make.

.PHONY: help all clean remove install update build test snapshot format anvil \
        deploy abi addr verify-sepolia       # Declare these as “phony” targets (always run, not tied to files of same name).

# ────────────────────────────────────────────────────────────────────────────────
# Basics (edit if you rename things)
# ────────────────────────────────────────────────────────────────────────────────
CONTRACT := ToDo                             # Contract name used by helper targets (e.g., ABI export).
SCRIPT   := script/DeployToDo.s.sol:DeployToDo  # Fully qualified script target for forge script.

# Default anvil key (first account from the standard test mnemonic)
DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:                                        # Prints quick usage tips.
	@echo "Usage:"                         # @ suppresses echoing the command itself.
	@echo "  make deploy [ARGS=...]"
	@echo "    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make verify-sepolia ADDR=0x...   # verify an existing address"
	@echo "  make addr [ARGS=...]             # print last deployed address from broadcast/"
	@echo ""

all: clean update build                      # “All” pipeline: clean → update modules → build.

# Clean the repo
clean  :; forge clean                        # Remove out/ and cache/ (fresh build).

# Remove modules (optional maintenance)
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules" || true
# ^ nukes submodules and lib/, recreates an empty .gitmodules, commits it; `|| true` prevents failure if there’s nothing to commit.

install :; forge install foundry-rs/forge-std@v1.8.2
# ^ example dependency; add more as needed.

# Update Dependencies
update:; forge update                        # Pull latest for installed libs.

build:; forge build                          # Compile contracts per foundry.toml.

test :; forge test -vv                       # Run tests with extra verbosity.

snapshot :; forge snapshot                   # Generate gas snapshots.

format :; forge fmt                          # Format Solidity files.

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1
# ^ Start a local chain with a fixed mnemonic, enable tracing, 1s block time (handy for demos).

# ────────────────────────────────────────────────────────────────────────────────
# Network switching (default: anvil; switch to sepolia with ARGS="--network sepolia")
# ────────────────────────────────────────────────────────────────────────────────
NETWORK_ARGS := --rpc-url http://127.0.0.1:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast -vvvv
# ^ Default CLI flags used by forge script when no --network sepolia is requested:
#   - rpc-url points at local anvil
#   - private-key is the known anvil account
#   - --broadcast actually sends txs (not a dry run)
#   - -vvvv = max verbosity (good logs)

CHAIN_ID := 31337                            # Used to locate the correct broadcast folder for addr target.

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)  # If ARGS contains “--network sepolia”…
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
	# ^ Switch to Sepolia:
	#   - rpc-url from your .env (Infura/Alchemy)
	#   - private-key deployer PK from .env
	#   - --verify triggers auto verification post-deploy
	#   - etherscan key required for verification
	#   - verbose logs
	CHAIN_ID := 11155111                     # Sepolia chain id (used by addr to read the right JSON).
endif

deploy:
	@forge script $(SCRIPT) $(NETWORK_ARGS)
# ^ Runs your DeployToDo.s.sol:DeployToDo script with the chosen NETWORK_ARGS (anvil by default, sepolia if ARGS asked).

# Export ABI for frontends
abi:
	@mkdir -p out
	@forge inspect $(CONTRACT) abi > out/$(CONTRACT).abi.json
	@echo "ABI saved to out/$(CONTRACT).abi.json"
# ^ Writes ABI JSON into out/ for easy frontend wiring.

addr:
	@jq -r '.transactions[0].contractAddress // .receipts[0].contractAddress' \
	  broadcast/$(word 1,$(subst :, ,$(SCRIPT)))/$(CHAIN_ID)/run-latest.json
# ^ Print last deployed address from forge’s broadcast artifact:
#   - $(subst :, ,$(SCRIPT)) → splits “script/DeployToDo.s.sol:DeployToDo” on “:” → “script/DeployToDo.s.sol DeployToDo”
#   - $(word 1, …) → take the first part = path folder under broadcast/
#   - CHAIN_ID picks the correct network folder
#   - jq extracts contractAddress (some forge versions place it in transactions[0], others inside receipts[0], hence the // fallback)

verify-sepolia:
	@test -n "$(ADDR)" || (echo "Usage: make verify-sepolia ADDR=0x..." && exit 1)
	@test -n "$(ETHERSCAN_API_KEY)" || (echo "✗ Set ETHERSCAN_API_KEY in .env" && exit 1)
	forge verify-contract \
	  --chain sepolia \
	  --etherscan-api-key $(ETHERSCAN_API_KEY) \
	  --watch \
	  $(ADDR) src/ToDo.sol:ToDo
# ^ Post-hoc verification if you already have an address:
#   - Requires ADDR=0x… and ETHERSCAN_API_KEY
#   - --watch waits for verification result