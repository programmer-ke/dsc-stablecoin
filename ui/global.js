/* The main UI logic */

const SUPPORTED_CHAIN_ID = "0xaa36a7";
const SUPPORTED_NETWORK_NAME = "Sepolia Testnet";


const EVENT_NAME_LIST = [
    "CheckWalletConnection",
    "RegisterWalletHandlers",
    "RequestWalletConnection",
    "WalletAccountsEmpty",
    "ErrorRequestingWalletConnection",
    "DisconnectWallet",
    "CheckSupportedChain",
    "UnsupportedChainDetected",
    "LoadAppState",
    "ResetAppState",
    "SwitchToSupportedNetwork",
    "ErrorSwitchingNetwork",
    "PromptManualNetworkConfig",
    "DepositCollateral",
    "DepositFailed",
    "DepositSucceeded",
    "DepositAndMint",
    "DepositAndMintSucceeded",
    "DepositAndMintFailed",
    "ErrorUpdatingHealthFactorPreview",
    "MintDsc",
    "MintSucceeded",
    "MintFailed",
    "BurnDsc",
    "BurnSucceeded",
    "BurnFailed",
];

const EVENTS = EVENT_NAME_LIST.reduce((map, name) => {
    map[name] = new CustomEvent(name);
    return map;
}, {});


const on = (eventObj, handler) => {
    if (!eventObj) {
        throw new Error("Event object is falsey or undefined.");
    }
    document.addEventListener(eventObj.type, handler);
};

const ConnectionState = Object.freeze({
    NOT_INSTALLED: "NOT_INSTALLED",
    DISCONNECTED: "DISCONNECTED",
    CONNECTION_REQUESTED: "CONNECTION_REQUESTED",
    CONNECTED: "CONNECTED",
    UNSUPPORTED_CHAIN: "UNSUPPORTED_CHAIN"
});

const BUTTON_CONFIG = {
    [ConnectionState.NOT_INSTALLED]: { text: "Install Wallet", disabled: true },
    [ConnectionState.DISCONNECTED]: { text: "Connect Wallet", disabled: false },
    [ConnectionState.CONNECTION_REQUESTED]: { text: "Connect Wallet", disabled: true },
    [ConnectionState.CONNECTED]: { text: "Disconnect", disabled: false },
    [ConnectionState.UNSUPPORTED_CHAIN]: { text: "Switch Network", disabled: false },
};

function createObservable(initialValue) {
    const _listeners = [];
    return {
        value: initialValue,
        set(newValue) {
            this.value = newValue;
            _listeners.forEach(fn => fn(newValue));
        },
        onChange(fn) {
            _listeners.push(fn);
        }
    };
}

const wallet = createObservable(ConnectionState.NOT_INSTALLED);
const connectedAccounts = createObservable([]);
const userHealthFactor = createObservable(null);
const totalDscMinted = createObservable(null);
const dscBalance = createObservable(null);
const wethBalance = createObservable(null);
const wbtcBalance = createObservable(null);
const collateralWethBalance = createObservable(null);
const collateralWethUsd = createObservable(null);
const collateralWbtcBalance = createObservable(null);
const collateralWbtcUsd = createObservable(null);
const collateralToken = createObservable(null);
const collateralToDeposit = createObservable(null);

const depositInProgress = createObservable(false);

const dscToMint = createObservable(null);
const mintInProgress = createObservable(false);
const depositAndMintInProgress = createObservable(false);

const dscToBurn = createObservable(null);
const burnInProgress = createObservable(false);

// Convert a human-readable amount (number or string) to wei as a BigInt.
// Safely handles exponent notation from parseFloat by using toFixed.
function toWei(amount, decimals) {
    return ethers.parseUnits(parseFloat(amount).toFixed(decimals), decimals);
}

// handlers
async function switchToSupportedNetwork() {
    try {
	await window.ethereum.request({
	    method: 'wallet_switchEthereumChain',
	    params: [{ chainId: SUPPORTED_CHAIN_ID}],
	});
	wallet.set(ConnectionState.CONNECTED);
    } catch (error) {
	if (error.code === 4902) {
	    document.dispatchEvent(EVENTS.PromptManualNetworkConfig);
	} else {
	    document.dispatchEvent(EVENTS.ErrorSwitchingNetwork);
	}
    }
}

function detectWallet() {
    if (window.ethereum) {
	wallet.set(ConnectionState.DISCONNECTED);
	document.dispatchEvent(EVENTS.RegisterWalletHandlers);
    }    else {
	wallet.set(ConnectionState.NOT_INSTALLED);
    }
}


async function requestWalletConnection() {

    // clear any previous application state
    document.dispatchEvent(EVENTS.ResetAppState);

    if (wallet.value === ConnectionState.NOT_INSTALLED) return;

    const old_state = wallet.value;
    wallet.set(ConnectionState.CONNECTION_REQUESTED);
    try {
	const accounts = await window.ethereum.request({
	    method: 'eth_requestAccounts'
	});

	if (accounts.length > 0) {
	    // success
	    connectedAccounts.set(accounts);
	    document.dispatchEvent(EVENTS.CheckSupportedChain);
	} else {
	    document.dispatchEvent(EVENTS.WalletAccountsEmpty);
	    console.warn("Empty accounts list!");
	}
	
    } catch (error) {
	console.error("error requesting wallet connection", error);
	document.dispatchEvent(EVENTS.ErrorRequestingWalletConnection);
    } finally {
	if (wallet.value == ConnectionState.CONNECTION_REQUESTED)
	    wallet.set(old_state);
    }
}


async function checkSupportedChain() {
    const chainId = await window.ethereum.request({ method: 'eth_chainId' });
    if (chainId !== SUPPORTED_CHAIN_ID) {
	document.dispatchEvent(EVENTS.UnsupportedChainDetected);
    } else {
	wallet.set(ConnectionState.CONNECTED);
	document.dispatchEvent(EVENTS.LoadAppState);
    }
}

function unsupportedChainDetected() {
    wallet.set(ConnectionState.UNSUPPORTED_CHAIN);
    showStatus(`Switch Network to ${SUPPORTED_NETWORK_NAME}.`, "error");
}


function walletConnectionButtonClickHandler() {
    if (wallet.value === ConnectionState.NOT_INSTALLED) {
	return;
    } else if (wallet.value === ConnectionState.DISCONNECTED) {
	document.dispatchEvent(EVENTS.RequestWalletConnection);
    } else if (wallet.value === ConnectionState.CONNECTED) {
	document.dispatchEvent(EVENTS.DisconnectWallet);
    } else if (wallet.value === ConnectionState.UNSUPPORTED_CHAIN) {
	document.dispatchEvent(EVENTS.SwitchToSupportedNetwork);
    } else {
	console.log("not implemented");
    }
}

function depositOnlyClickHandler() {
    document.dispatchEvent(EVENTS.DepositCollateral);
}

function disconnectWallet() {
    connectedAccounts.set([]);
    wallet.set(ConnectionState.DISCONNECTED);
    document.dispatchEvent(EVENTS.ResetAppState);
}

function notifyErrorSwitchingNetwork() {
    showStatus(`Could not switch to ${SUPPORTED_NETWORK_NAME}. Please try again.`, "error");
}

async function promptUserToConfigureNetwork() {
    try {
        await window.ethereum.request({
            method: 'wallet_addEthereumChain',
            params: [{
                chainId: SUPPORTED_CHAIN_ID,
                chainName: SUPPORTED_NETWORK_NAME,
                rpcUrls: ['https://rpc.sepolia.org'],
                blockExplorerUrls: ['https://sepolia.etherscan.io'],
                nativeCurrency: {
                    name: 'SepoliaETH',
                    symbol: 'ETH',
                    decimals: 18,
                },
            }],
        });

	document.dispatchEvent(EVENTS.CheckSupportedChain);
    } catch (addError) {
        // User rejected or method unavailable – fallback to manual instructions
        showStatus(
            `Please add the ${SUPPORTED_NETWORK_NAME} network manually in your wallet. Chain ID: 11155111, RPC: https://rpc.sepolia.org`,
            'error'
        );
    }
}

function registerWalletHandlers() {
    window.ethereum.on('chainChanged', () => {
	if (wallet.value !== ConnectionState.DISCONNECTED)
	    // only reset connection if was previously connected
	    document.dispatchEvent(EVENTS.RequestWalletConnection);
    });

    window.ethereum.on('accountsChanged', (accounts) => {
	if (accounts.length === 0) {
	    document.dispatchEvent(EVENTS.DisconnectWallet);
	    return;
	}

	const current = connectedAccounts.value;
	if (current.length === accounts.length && current[0] == accounts[0]) {
	    // No changes, ignore
	    return;
	}

	connectedAccounts.set(accounts);

	if (current[0] !== accounts[0] && wallet.value !== ConnectionState.DISCONNECTED)
	    // first account changed and was previously connected
	    document.dispatchEvent(EVENTS.RequestWalletConnection);
    });
}

// Reset user session
function resetAppState() {
    resetContractInteractionState();

    userHealthFactor.set(null);
    totalDscMinted.set(null);
    dscBalance.set(null);
    wethBalance.set(null);
    wbtcBalance.set(null);
    collateralWethBalance.set(null);
    collateralWethUsd.set(null);
    collateralWbtcBalance.set(null);
    collateralWbtcUsd.set(null);
    mintInProgress.set(false);
    depositInProgress.set(false);
    depositAndMintInProgress.set(false);
    burnInProgress.set(false);
}

async function loadAppState() {
    const user = connectedAccounts.value[0];

    const dataloaders = [
	{ fetch: () => fetchHealthFactor(user), target: userHealthFactor },
	{ fetch: async () => (await fetchAccountInformation(user))[0], target: totalDscMinted },
	{ fetch: () => getErcBalanceOf('dsc', user), target: dscBalance },
	{ fetch: () => getErcBalanceOf('weth', user), target: wethBalance },
	{ fetch: () => getErcBalanceOf('wbtc', user), target: wbtcBalance },
        {
            fetch: async () => {
                const balance = await fetchCollateralBalance(WETH_ADDRESS, user);
                const usd = balance > 0n ? await fetchUsdValue(WETH_ADDRESS, balance) : 0n;
                return { balance, usd };
            },
            target: {
                set: ({ balance, usd }) => {
                    collateralWethBalance.set(balance);
                    collateralWethUsd.set(usd);
                }
            }
        },
        {
            fetch: async () => {
                const balance = await fetchCollateralBalance(WBTC_ADDRESS, user);
                const usd = balance > 0n ? await fetchUsdValue(WBTC_ADDRESS, balance) : 0n;
                return { balance, usd };
            },
            target: {
                set: ({ balance, usd }) => {
                    collateralWbtcBalance.set(balance);
                    collateralWbtcUsd.set(usd);
                }
            }
        }
    ];

    try {
	for (const { fetch, target } of dataloaders) {
	    const value = await fetch();
	    if (_sameUserIsConnected(user)) {
		target.set(value);
	    } else {
		return;
	    }
	}
    } catch (error) {
	console.log("Error loading app state", error);
	showStatus("Something went wrong while refreshing data", "error");
    }
}

function _sameUserIsConnected(user) {
    return wallet.value == ConnectionState.CONNECTED && connectedAccounts.value[0] == user;
}


const services = {
    depositCollateral: async () => {
	if (!canDepositCollateral()) return;

	try {
	    depositInProgress.set(true);
	    const tokenName = collateralToken.value;
	    const decimals = ERC20_CONFIG[tokenName].decimals;
	    const amountInWei = toWei(collateralToDeposit.value, decimals);
	    await depositCollateral(tokenName, amountInWei);
	    document.dispatchEvent(EVENTS.DepositSucceeded);
	} catch (error) {
	    console.error(error);
	    document.dispatchEvent(EVENTS.DepositFailed);
	} finally {
	    depositInProgress.set(false);
	}
    },
    mintDsc: async () => {
        if (!canMintDsc()) return;

        try {
            mintInProgress.set(true);
            const amount = dscToMint.value;
            const amountInWei = toWei(amount, 18);
            await mintDsc(amountInWei);
            document.dispatchEvent(EVENTS.MintSucceeded);
        } catch (error) {
            console.error(error);
            document.dispatchEvent(EVENTS.MintFailed);
        } finally {
            mintInProgress.set(false);
        }
    },
    depositAndMint: async () => {
        if (!canDepositAndMint()) return;

        try {
            depositAndMintInProgress.set(true);
            const tokenName = collateralToken.value;
            const decimals = ERC20_CONFIG[tokenName].decimals;
            const collateralInWei = toWei(collateralToDeposit.value, decimals);
            const dscInWei = toWei(dscToMint.value, 18);
            await depositCollateralAndMintDsc(tokenName, collateralInWei, dscInWei);
            document.dispatchEvent(EVENTS.DepositAndMintSucceeded);
        } catch (error) {
            console.error(error);
            document.dispatchEvent(EVENTS.DepositAndMintFailed);
        } finally {
            depositAndMintInProgress.set(false);
        }
    },
    burnDsc: async () => {
        if (!canBurnDsc()) return;

        try {
            burnInProgress.set(true);
            const amount = dscToBurn.value;
            const amountInWei = toWei(amount, 18);
            await burnDsc(amountInWei);
            document.dispatchEvent(EVENTS.BurnSucceeded);
        } catch (error) {
            console.error(error);
            document.dispatchEvent(EVENTS.BurnFailed);
        } finally {
            burnInProgress.set(false);
        }
    },
}


// custom event mappings
on(EVENTS.RegisterWalletHandlers, registerWalletHandlers);
on(EVENTS.CheckWalletConnection, detectWallet);
on(EVENTS.DisconnectWallet, disconnectWallet);
on(EVENTS.RequestWalletConnection, requestWalletConnection);
on(EVENTS.CheckSupportedChain, checkSupportedChain);
on(EVENTS.UnsupportedChainDetected, unsupportedChainDetected);
on(EVENTS.SwitchToSupportedNetwork, switchToSupportedNetwork);
on(EVENTS.ErrorSwitchingNetwork, notifyErrorSwitchingNetwork);
on(EVENTS.PromptManualNetworkConfig, promptUserToConfigureNetwork);
on(EVENTS.ResetAppState, resetAppState);
on(EVENTS.LoadAppState, loadAppState);
on(EVENTS.DepositCollateral, services.depositCollateral);
on(EVENTS.ErrorUpdatingHealthFactorPreview, () => {
    showStatus("Something went wrong. Please try again.", "error");
});
on(EVENTS.ErrorRequestingWalletConnection, () => {
  showStatus("Something went wrong. Please try again.", "error");
});
on(EVENTS.WalletAccountsEmpty, () => {
  showStatus("Something went wrong. Please try again.", "error");
});
on(EVENTS.DepositFailed, () => {
    showStatus("Something went wrong. Please try again.", "error");
});
on(EVENTS.DepositSucceeded, () => {
    collateralAmountInput.value = "";
    collateralToDeposit.set(0);
    document.dispatchEvent(EVENTS.LoadAppState);
});

on(EVENTS.DepositAndMint, services.depositAndMint);
on(EVENTS.DepositAndMintSucceeded, () => {
    collateralAmountInput.value = "";
    dscAmountInput.value = "";
    collateralToDeposit.set(0);
    dscToMint.set(0);
    document.dispatchEvent(EVENTS.LoadAppState);
});
on(EVENTS.DepositAndMintFailed, () => {
    showStatus("Something went wrong. Please try again.", "error");
});

on(EVENTS.MintDsc, services.mintDsc);
on(EVENTS.MintSucceeded, () => {
    dscAmountInput.value = "";
    dscToMint.set(0);
    document.dispatchEvent(EVENTS.LoadAppState);
});
on(EVENTS.MintFailed, () => {
    showStatus("Something went wrong. Please try again.", "error");
});

on(EVENTS.BurnDsc, services.burnDsc);
on(EVENTS.BurnSucceeded, () => {
    document.getElementById("burn-dsc-amount").value = "";
    dscToBurn.set(0);
    document.dispatchEvent(EVENTS.LoadAppState);
});
on(EVENTS.BurnFailed, () => {
    showStatus("Something went wrong. Please try again.", "error");
});


// Connection button listeners
const walletConnectionButton = document.querySelector("#connect-wallet-button");
walletConnectionButton.addEventListener("click", walletConnectionButtonClickHandler);

const depositOnlyButton = document.getElementById("btn-deposit-only");
depositOnlyButton.addEventListener("click", depositOnlyClickHandler);

const mintOnlyButton = document.getElementById("btn-mint-only");
mintOnlyButton.addEventListener("click", () => {
    document.dispatchEvent(EVENTS.MintDsc);
});

const depositAndMintButton = document.getElementById("btn-deposit-mint");
depositAndMintButton.addEventListener("click", () => {
    document.dispatchEvent(EVENTS.DepositAndMint);
});

const burnOnlyButton = document.getElementById("btn-burn-only");
burnOnlyButton.addEventListener("click", () => {
    document.dispatchEvent(EVENTS.BurnDsc);
});

// collateral token bindings
function _collateralTokenAddress(selectValue) {
    return selectValue == "weth" ? WETH_ADDRESS : WBTC_ADDRESS;
}
const collateralTokenSelector = document.getElementById("collateral-token");
collateralToken.set(collateralTokenSelector.value);
collateralTokenSelector.addEventListener("change", () => {
    collateralToken.set(collateralTokenSelector.value);
});


const collateralAmountInput = document.getElementById("collateral-amount");
collateralToDeposit.set(parseFloat(collateralAmountInput.value) || 0);
collateralAmountInput.addEventListener("change", () => {
    collateralToDeposit.set(parseFloat(collateralAmountInput.value) || 0);
});

const dscAmountInput = document.getElementById("dsc-amount");
dscToMint.set(parseFloat(dscAmountInput.value) || 0);
dscAmountInput.addEventListener("change", () => {
    dscToMint.set(parseFloat(dscAmountInput.value) || 0);
});

const burnDscAmountInput = document.getElementById("burn-dsc-amount");
dscToBurn.set(parseFloat(burnDscAmountInput.value) || 0);
burnDscAmountInput.addEventListener("change", () => {
    dscToBurn.set(parseFloat(burnDscAmountInput.value) || 0);
});

const mintMaxLink = document.getElementById("mint-max-link");
if (mintMaxLink) {
    mintMaxLink.addEventListener("click", (e) => {
        e.preventDefault();
        const tokenName = collateralToken.value;
        let balance = null;
        let decimals = 18;

        if (tokenName === "weth") {
            balance = wethBalance.value;
        } else if (tokenName === "wbtc") {
            balance = wbtcBalance.value;
            decimals = ERC20_CONFIG.wbtc.decimals;
        }

        if (balance !== null) {
            const formattedBalance = ethers.formatUnits(balance, decimals);
            collateralAmountInput.value = formattedBalance;
            // Manually update the observable since programmatic value changes don't trigger 'change' events
            collateralToDeposit.set(parseFloat(formattedBalance) || 0);
        }
    });
}


const maxBurnLink = document.getElementById("max-burn-link");
if (maxBurnLink) {
    maxBurnLink.addEventListener("click", (e) => {
        e.preventDefault();
        const balance = dscBalance.value;
        const debt = totalDscMinted.value;
        if (balance === null || debt === null) return;

        const maxWei = balance < debt ? balance : debt;
        const formatted = ethers.formatUnits(maxWei, 18);
        burnDscAmountInput.value = formatted;
        dscToBurn.set(parseFloat(formatted) || 0);
    });
}


// Deposit & Mint Health Factor Preview
const refreshDepositMintHfPreviewLink = document.getElementById("refresh-deposit-mint-hf-preview");
if (refreshDepositMintHfPreviewLink) {
    refreshDepositMintHfPreviewLink.addEventListener("click", async (e) => {
        e.preventDefault();

        if (wallet.value !== ConnectionState.CONNECTED) {
            return;
        }

        const depositAmount = collateralToDeposit.value;
        const mintAmount = dscToMint.value;

        // If both are zero/empty, show nothing
        if ((!depositAmount || depositAmount <= 0) && (!mintAmount || mintAmount <= 0)) {
            document.getElementById("deposit-mint-preview-new-hf").textContent = "--";
            return;
        }

        try {
            // 1. Calculate additional collateral USD from deposit (if any)
            let depositUsd = 0n;
            if (depositAmount && depositAmount > 0) {
                const tokenName = collateralToken.value;
                const tokenAddress = tokenName === "weth" ? WETH_ADDRESS : WBTC_ADDRESS;
                const decimals = ERC20_CONFIG[tokenName].decimals;
                const amountInWei = toWei(depositAmount, decimals);
                depositUsd = await fetchUsdValue(tokenAddress, amountInWei);
            }

            const existingWethUsd = collateralWethUsd.value ?? 0n;
            const existingWbtcUsd = collateralWbtcUsd.value ?? 0n;
            const newTotalCollateralUsd = existingWethUsd + existingWbtcUsd + depositUsd;

            // 2. Calculate new total debt (existing + mint amount)
            const existingDebt = totalDscMinted.value ?? 0n;
            let newDebt = existingDebt;
            if (mintAmount && mintAmount > 0) {
                const mintAmountInWei = toWei(mintAmount, 18);
                newDebt = existingDebt + mintAmountInWei;
            }

            // 3. Compute new health factor
            const newHf = await calculateHealthFactor(newDebt, newTotalCollateralUsd);

            // 4. Display result
            const max_uint256 = (2n ** 256n) - 1n;
            let text;
            if (newHf === max_uint256) {
                text = "OK";
            } else {
                text = ethers.formatUnits(newHf);
            }

            const previewEl = document.getElementById("deposit-mint-preview-new-hf");
            previewEl.textContent = text;

            if (newHf < ethers.parseUnits("1", 18)) {
                previewEl.setAttribute("data-state", "alert");
            } else {
                previewEl.setAttribute("data-state", "safe");
            }
        } catch (err) {
            console.error("Preview failed", err);
            document.getElementById("deposit-mint-preview-new-hf").textContent = "--";
            document.dispatchEvent(EVENTS.ErrorUpdatingHealthFactorPreview);
        }
    });
}

// Burn & Redeem Health Factor Preview
const refreshBurnRedeemHfPreviewLink = document.getElementById("refresh-burn-redeem-hf-preview");
if (refreshBurnRedeemHfPreviewLink) {
    refreshBurnRedeemHfPreviewLink.addEventListener("click", async (e) => {
        e.preventDefault();

        if (wallet.value !== ConnectionState.CONNECTED) {
            return;
        }

        const burnAmount = dscToBurn.value;
        const existingDebt = totalDscMinted.value;

        // If no burn amount entered, reset the preview
        if (!burnAmount || burnAmount <= 0) {
            document.getElementById("burn-redeem-preview-new-hf").textContent = "--";
            return;
        }

        try {
            const burnWei = toWei(burnAmount, 18);

            if (existingDebt === null || burnWei > existingDebt) {
                document.getElementById("burn-redeem-preview-new-hf").textContent = "--";
                showStatus("Burn amount exceeds debt", "error");
                return;
            }

            const newDebt = existingDebt - burnWei;
            const existingWethUsd = collateralWethUsd.value ?? 0n;
            const existingWbtcUsd = collateralWbtcUsd.value ?? 0n;
            const newTotalCollateralUsd = existingWethUsd + existingWbtcUsd;

            const newHf = await calculateHealthFactor(newDebt, newTotalCollateralUsd);

            const max_uint256 = (2n ** 256n) - 1n;
            let text;
            if (newHf === max_uint256) {
                text = "OK";
            } else {
                text = ethers.formatUnits(newHf);
            }

            const previewEl = document.getElementById("burn-redeem-preview-new-hf");
            previewEl.textContent = text;

            if (newHf < ethers.parseUnits("1", 18)) {
                previewEl.setAttribute("data-state", "alert");
            } else {
                previewEl.setAttribute("data-state", "safe");
            }
        } catch (err) {
            console.error("Burn preview failed", err);
            document.getElementById("burn-redeem-preview-new-hf").textContent = "--";
            document.dispatchEvent(EVENTS.ErrorUpdatingHealthFactorPreview);
        }
    });
}


// state change listeners

function _validDepositTokenAmount() {
    if (collateralToDeposit.value <= 0) {
	return false;
    } else if (collateralToken.value === null) {
	return false;
    } else {
	const tokenName = collateralToken.value;
	const tokenBalance = tokenName === "weth" ? wethBalance.value : wbtcBalance.value;
	if (tokenBalance === null) {
	    // balance not yet loaded, optimistically allow deposits
	    return true;
	}

	const decimals = ERC20_CONFIG[tokenName].decimals;
	const amountInWei = toWei(collateralToDeposit.value, decimals);

	if (amountInWei > tokenBalance) {
	    return false;
	} else {
	    return true;
	}
    }
}

function canDepositCollateral() {
    const isConnected = wallet.value === ConnectionState.CONNECTED;
    return isConnected && _validDepositTokenAmount();
}

function updateDepositOnlyButton() {
    const notBusy = !depositInProgress.value;
    depositOnlyButton.disabled = !(canDepositCollateral() && notBusy);
}

function canMintDsc() {
    const isConnected = wallet.value === ConnectionState.CONNECTED;
    const amount = dscToMint.value;
    return isConnected && amount > 0;
}

function updateMintOnlyButton() {
    const notBusy = !mintInProgress.value;
    mintOnlyButton.disabled = !(canMintDsc() && notBusy);
}

function canDepositAndMint() {
    const isConnected = wallet.value === ConnectionState.CONNECTED;
    return isConnected && _validDepositTokenAmount() && dscToMint.value > 0;
}

function updateDepositAndMintButton() {
    const notBusy = !depositAndMintInProgress.value;
    const btn = document.getElementById("btn-deposit-mint");
    btn.disabled = !(canDepositAndMint() && notBusy);
}

function canBurnDsc() {
    const isConnected = wallet.value === ConnectionState.CONNECTED;
    const amount = dscToBurn.value;
    if (!isConnected || !amount || amount <= 0) return false;

    // Convert to wei for precise comparisons
    const amountInWei = toWei(amount, 18);
    const balance = dscBalance.value;
    const debt = totalDscMinted.value;

    // If data hasn't loaded yet, optimistically allow
    if (balance === null || debt === null) return true;

    // Must not exceed wallet balance
    if (amountInWei > balance) return false;
    // Must not exceed current debt
    if (amountInWei > debt) return false;

    return true;
}

function updateBurnOnlyButton() {
    const notBusy = !burnInProgress.value;
    const btn = document.getElementById("btn-burn-only");
    btn.disabled = !(canBurnDsc() && notBusy);
}

collateralToDeposit.onChange(updateDepositOnlyButton);
collateralToken.onChange(updateDepositOnlyButton);
wallet.onChange(updateDepositOnlyButton);
depositInProgress.onChange(updateDepositOnlyButton);

dscToMint.onChange(updateMintOnlyButton);
wallet.onChange(updateMintOnlyButton);
mintInProgress.onChange(updateMintOnlyButton);

collateralToDeposit.onChange(updateDepositAndMintButton);
collateralToken.onChange(updateDepositAndMintButton);
dscToMint.onChange(updateDepositAndMintButton);
wallet.onChange(updateDepositAndMintButton);
depositAndMintInProgress.onChange(updateDepositAndMintButton);

dscToBurn.onChange(updateBurnOnlyButton);
dscBalance.onChange(updateBurnOnlyButton);
totalDscMinted.onChange(updateBurnOnlyButton);
wallet.onChange(updateBurnOnlyButton);
burnInProgress.onChange(updateBurnOnlyButton);

wallet.onChange(state => {
    const btn = walletConnectionButton;
    const config = BUTTON_CONFIG[state];
    if (config) {
        btn.textContent = config.text;
        btn.disabled = config.disabled;
    }
});


connectedAccounts.onChange(accounts => {
    const connectedAddrLabel = document.querySelector("#connected-address-label");
    
    if (accounts.length > 0) {
	const addr = accounts[0];
	connectedAddrLabel.textContent = `Connected as ${truncateAddr(addr)}`;
    } else {
	connectedAddrLabel.textContent = "";
    }
});


userHealthFactor.onChange(value => {

    let text; 
    let state;
    
    if (value == null) {
	text = "--";
	state = "unknown";
    } else {
	const max_uint256 = (2n ** 256n) - 1n;
	if (value === max_uint256)
	    // 2 ** 256 implies no debt (infinite health)
	    text = "OK";
	else
	    text = ethers.formatUnits(value);
	if (value < 1e18)
	    state = "alert";
	else if (value < 1.2e18)
	    state = "warning";
	else
	    state = "safe";
    }

    document.querySelectorAll("dashboard-number.health-factor").forEach((elem, index) => {
	elem.textContent = text;
	elem.setAttribute("data-state", state);
    });

});


function _updateDashboardNumber(value, elementId, decimals = 18) {
    let text;
    if (value == null)
	text = "--";
    else
	text = ethers.formatUnits(value, decimals);
    document.getElementById(elementId).textContent = text;
}

totalDscMinted.onChange(value => {
    _updateDashboardNumber(value, "total-dsc-debt");
    _updateDashboardNumber(value, "current-debt");
});


dscBalance.onChange(value => {
    _updateDashboardNumber(value, "dsc-balance");
});


wethBalance.onChange(value => {
    _updateDashboardNumber(value, "weth-balance");
});

wbtcBalance.onChange(value => {
    _updateDashboardNumber(value, "wbtc-balance", ERC20_CONFIG.wbtc.decimals);
});

collateralWethBalance.onChange(value => {
    _updateDashboardNumber(value, "collateral-weth-balance");
});

collateralWethUsd.onChange(value => {
    _updateDashboardNumber(value, "collateral-weth-usd");
});

collateralWbtcBalance.onChange(value => {
    _updateDashboardNumber(value, "collateral-wbtc-balance", ERC20_CONFIG.wbtc.decimals);
});

collateralWbtcUsd.onChange(value => {
    _updateDashboardNumber(value, "collateral-wbtc-usd");
});

function updateWalletBalanceDisplay() {
    const tokenName = collateralToken.value;
    let balance = null;
    let decimals = 18;

    if (tokenName === "weth") {
        balance = wethBalance.value;
    } else if (tokenName === "wbtc") {
        balance = wbtcBalance.value;
        decimals = ERC20_CONFIG.wbtc.decimals;
    }

    _updateDashboardNumber(balance, "wallet-balance", decimals);
}

collateralToken.onChange(updateWalletBalanceDisplay);
wethBalance.onChange(updateWalletBalanceDisplay);
wbtcBalance.onChange(updateWalletBalanceDisplay);


function truncateAddr(address) {
    return address.slice(0, 5) + "..." + address.slice(-3);
}

function showStatus(message, type = 'error') {
  const el = document.getElementById('global-status');
  el.textContent = message;
  el.className = type;          // 'error' or 'success'
  el.hidden = false;
  // Auto-hide after 5 seconds
  setTimeout(() => { el.hidden = true; }, 5000);
}

document.dispatchEvent(EVENTS.CheckWalletConnection);
