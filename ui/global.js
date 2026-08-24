const ConnectionState = Object.freeze({
    NOT_INSTALLED: "NOT_INSTALLED",
    INSTALLED: "INSTALLED"
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

// commands
const CheckWalletInstallation = new CustomEvent("CheckWalletInstallation");

// events
const WalletInstalled = new CustomEvent("WalletInstalled");
const WalletNotInstalled = new CustomEvent("WalletNotInstalled");

// handlers
function detectWallet() {
    if (window.ethereum)
	document.dispatchEvent(WalletInstalled);
    else
	document.dispatchEvent(WalletNotInstalled);
}

// event mappings
document.addEventListener("CheckWalletInstallation",  detectWallet);
document.addEventListener("WalletInstalled", () => {
    wallet.setState(ConnectionState.INSTALLED);
});

document.addEventListener("WalletNotInstalled", () => {
    wallet.setState(ConnectionState.NOT_INSTALLED);
});

// state change mappings
wallet.onChange(state => {
    const btn = document.querySelector("#connect-wallet-button");
    if (state === ConnectionState.NOT_INSTALLED) {
	btn.textContent = "Install Wallet";
	btn.disabled = true;
    } else if (state === ConnectionState.INSTALLED) {
	btn.textContent = "Connect Wallet";
	btn.disabled = false;
    }
});

document.dispatchEvent(CheckWalletInstallation);
