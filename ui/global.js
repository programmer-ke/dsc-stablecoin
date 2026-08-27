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
    INSTALLED: "INSTALLED",
    CONNECTION_REQUESTED: "CONNECTION_REQUESTED",
    CONNECTED: "CONNECTED",
    UNSUPPORTED_CHAIN: "UNSUPPORTED_CHAIN"
});

const wallet = {
    state: ConnectionState.NOT_INSTALLED,
    _listeners: [],
    setState(newState) {
	this.state = newState;
	this._listeners.forEach(fn => fn(newState));
    },
    onChange(fn) {
	this._listeners.push(fn);
    }
};

const connectedAccounts = {
    accounts: [],
    _listeners: [],
    setAccounts(accounts) {
	this.accounts = accounts;
	this._listeners.forEach(fn => fn(accounts));
    },
    onChange(fn) {
	this._listeners.push(fn);
    }
};

const userHealthFactor = {
    value: null,
    _listeners: [],
    setValue(value) {
	this.value = value;
	this._listeners.forEach(fn => fn(value));
    },
    onChange(fn) {
	this._listeners.push(fn);
    }
};


// handlers
async function switchToSupportedNetwork() {
    try {
	await window.ethereum.request({
	    method: 'wallet_switchEthereumChain',
	    params: [{ chainId: SUPPORTED_CHAIN_ID}],
	});
	wallet.setState(ConnectionState.CONNECTED);
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
	wallet.setState(ConnectionState.INSTALLED);
	document.dispatchEvent(EVENTS.RegisterWalletHandlers);
    }    else {
	wallet.setState(ConnectionState.NOT_INSTALLED);
    }
}


async function requestWalletConnection() {

    // clear any previous application state
    document.dispatchEvent(EVENTS.ResetAppState);

    if (wallet.state === ConnectionState.NOT_INSTALLED) return;

    const old_state = wallet.state;
    wallet.setState(ConnectionState.CONNECTION_REQUESTED);
    try {
	const accounts = await window.ethereum.request({
	    method: 'eth_requestAccounts'
	});

	if (accounts.length > 0) {
	    // success
	    connectedAccounts.setAccounts(accounts);
	    document.dispatchEvent(EVENTS.CheckSupportedChain);
	} else {
	    document.dispatchEvent(EVENTS.WalletAccountsEmpty);
	    console.warn("Empty accounts list!");
	}
	
    } catch (error) {
	console.error("error requesting wallet connection", error);
	document.dispatchEvent(EVENTS.ErrorRequestingWalletConnection);
    } finally {
	if (wallet.state == ConnectionState.CONNECTION_REQUESTED)
	    wallet.setState(old_state);
    }
}


async function checkSupportedChain() {
    const chainId = await window.ethereum.request({ method: 'eth_chainId' });
    if (chainId !== SUPPORTED_CHAIN_ID) {
	document.dispatchEvent(EVENTS.UnsupportedChainDetected);
    } else {
	wallet.setState(ConnectionState.CONNECTED);
	document.dispatchEvent(EVENTS.LoadAppState);
    }
}

function unsupportedChainDetected() {
    wallet.setState(ConnectionState.UNSUPPORTED_CHAIN);
    showStatus(`Switch Network to ${SUPPORTED_NETWORK_NAME}.`, "error");
}


function walletConnectionButtonClickHandler() {
    if (wallet.state === ConnectionState.NOT_INSTALLED) {
	return;
    } else if (wallet.state === ConnectionState.INSTALLED) {
	document.dispatchEvent(EVENTS.RequestWalletConnection);
    } else if (wallet.state === ConnectionState.CONNECTED) {
	document.dispatchEvent(EVENTS.DisconnectWallet);
    } else if (wallet.state === ConnectionState.UNSUPPORTED_CHAIN) {
	document.dispatchEvent(EVENTS.SwitchToSupportedNetwork);
    } else {
	console.log("not implemented");
    }
}

function disconnectWallet() {
    connectedAccounts.setAccounts([]);
    wallet.setState(ConnectionState.INSTALLED);
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
	if (wallet.state !== ConnectionState.INSTALLED)
	    // only reset connection if was previously connected
	    document.dispatchEvent(EVENTS.RequestWalletConnection);
    });

    window.ethereum.on('accountsChanged', (accounts) => {
	if (accounts.length === 0) {
	    document.dispatchEvent(EVENTS.DisconnectWallet);
	    return;
	}

	const current = connectedAccounts.accounts;
	if (current.length === accounts.length && current[0] == accounts[0]) {
	    // No changes, ignore
	    return;
	}

	connectedAccounts.setAccounts(accounts);

	if (current[0] !== accounts[0] && wallet.state !== ConnectionState.INSTALLED)
	    // first account changed and was previously connected
	    document.dispatchEvent(EVENTS.RequestWalletConnection);
    });
}

// Reset user session
function resetAppState() {
    resetContractInteractionState();

    userHealthFactor.setValue(null);
    
}

async function loadAppState() {
    const user = connectedAccounts.accounts[0];
    const healthFactor = await fetchHealthFactor(connectedAccounts.accounts[0]);
    if (wallet.state == ConnectionState.CONNECTED && connectedAccounts.accounts[0] == user) {
	userHealthFactor.setValue(healthFactor);	
    }
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
    if (state === ConnectionState.NOT_INSTALLED) {
	btn.textContent = "Install Wallet";
	btn.disabled = true;
    } else if (state === ConnectionState.INSTALLED) {
	btn.textContent = "Connect Wallet";
	btn.disabled = false;
    } else if (state == ConnectionState.CONNECTION_REQUESTED) {
	btn.disabled = true;
    } else if (state == ConnectionState.CONNECTED) {
	btn.disabled = false;
	btn.textContent = "Disconnect";
    } else if (state == ConnectionState.UNSUPPORTED_CHAIN) {
	btn.disabled = false;
	btn.textContent = "Switch Network";
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
    const hfElem = document.getElementById("health-factor");

    let text; 
    let state;
    let ether = BigInt(10e16);
    
    if (value == null) {
	text = "--";
	state = "unknown";
    } else if (value >= ether) {
	text = ethers.formatUnits(value);
	state = "safe";
    } else {
	text = ethers.formatUnits(value);
	state = "alert";
    }

    hfElem.textContent = text;
    hfElem.setAttribute("data-state", state);
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
