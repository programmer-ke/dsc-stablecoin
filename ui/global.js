const EVENT_NAME_LIST = [
    "CheckWalletConnection",
    "RequestWalletConnection",
    "WalletAccountsEmpty",
    "ErrorRequestingWalletConnection",
    "DisconnectWallet",
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

// handlers
function detectWallet() {
    if (window.ethereum) {
	wallet.setState(ConnectionState.INSTALLED);
    }    else {
	wallet.setState(ConnectionState.NOT_INSTALLED);
    }
}


async function checkPreviousConnection() {
  if (wallet.state !== ConnectionState.INSTALLED) return;

  try {
    const accounts = await window.ethereum.request({
      method: "eth_accounts",
    });

    if (accounts.length > 0) {
      connectedAccounts.setAccounts(accounts);
      wallet.setState(ConnectionState.CONNECTED);
    }
  } catch (error) {
    console.warn("eth_accounts check failed", error);
  }
}

async function requestWalletConnection() {
    if (wallet.state === ConnectionState.NOT_INSTALLED) {
	return;
    }

    const old_state = wallet.state;
    wallet.setState(ConnectionState.CONNECTION_REQUESTED);
    try {
	const accounts = await window.ethereum.request({
	    method: 'eth_requestAccounts'
	});

	if (accounts.length > 0) {
	    // success
	    connectedAccounts.setAccounts(accounts);
	    wallet.setState(ConnectionState.CONNECTED);
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


function walletConnectionButtonClickHandler() {
    if (wallet.state === ConnectionState.NOT_INSTALLED) {
	return;
    } else if (wallet.state === ConnectionState.INSTALLED) {
	document.dispatchEvent(EVENTS.RequestWalletConnection);
    } else if (wallet.state === ConnectionState.CONNECTED) {
	document.dispatchEvent(EVENTS.DisconnectWallet);
    } else {
	console.log("not implemented");
    }
}

function disconnectWallet() {
    connectedAccounts.setAccounts([]);
    wallet.setState(ConnectionState.INSTALLED);
}

// event mappings
on(EVENTS.CheckWalletConnection, detectWallet);
on(EVENTS.DisconnectWallet, disconnectWallet);
on(EVENTS.RequestWalletConnection, requestWalletConnection);
on(EVENTS.ErrorRequestingWalletConnection, () => {
  showStatus("Something went wrong. Please try again.", "error");
});
on(EVENTS.WalletAccountsEmpty, () => {
  showStatus("Something went wrong. Please try again.", "error");
});

const walletConnectionButton = document.querySelector("#connect-wallet-button");
walletConnectionButton.addEventListener("click", walletConnectionButtonClickHandler);

// state change mappings
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
