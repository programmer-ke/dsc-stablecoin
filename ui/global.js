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
    
}

async function loadAppState() {
    const user = connectedAccounts.value[0];

    const dataloaders = [
	{ fetch: () => fetchHealthFactor(user), target: userHealthFactor },
	{ fetch: async () => (await fetchAccountInformation(user))[0], target: totalDscMinted },
	{ fetch: () => getErcBalanceOf('dsc', user), target: dscBalance },
	{ fetch: () => getErcBalanceOf('weth', user), target: wethBalance },
	{ fetch: () => getErcBalanceOf('wbtc', user), target: wbtcBalance },
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


// event mappings
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
on(EVENTS.ErrorRequestingWalletConnection, () => {
  showStatus("Something went wrong. Please try again.", "error");
});
on(EVENTS.WalletAccountsEmpty, () => {
  showStatus("Something went wrong. Please try again.", "error");
});

const walletConnectionButton = document.querySelector("#connect-wallet-button");
walletConnectionButton.addEventListener("click", walletConnectionButtonClickHandler);

// state change listeners
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
	max_uint256 = BigInt(2**256) - 1n;
	if (value === max_uint256)
	    // 2 ** 256 implies no debt (infinite health)
	    text = "N/A";
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
    if (value == null)
	text = "--";
    else
	text = ethers.formatUnits(value, decimals);
    document.getElementById(elementId).textContent = text;
}

totalDscMinted.onChange(value => {
    _updateDashboardNumber(value, "total-dsc-debt");
});


dscBalance.onChange(value => {
    _updateDashboardNumber(value, "dsc-balance");
});


wethBalance.onChange(value => {
    _updateDashboardNumber(value, "weth-balance");
});

wbtcBalance.onChange(value => {
    _updateDashboardNumber(value, "wbtc-balance", 8);
});


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
