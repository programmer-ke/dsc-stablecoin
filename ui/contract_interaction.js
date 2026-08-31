/* Contract config and interaction */

const DSC_ADDRESS = "0x3788a945770b35c7909cc3037ca0d56b03f6edc0";
const DSC_ENGINE_ADDRESS = "0xbf66637b035efce43dd8b930cc7edadb87f08afc";
const WBTC_ADDRESS = "0x92f3B59a79bFf5dc60c0d59eA13a44D082B2bdFC";
const WETH_ADDRESS = "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14";

const ERC20_CONFIG = {
    dsc: { address: DSC_ADDRESS, abi: DSC_ABI, decimals: 18 },
    weth: { address: WETH_ADDRESS, abi: SEPOLIA_WETH_ABI, decimals: 18 },
    wbtc: { address: WBTC_ADDRESS, abi: SEPOLIA_WBTC_ABI, decimals: 8 },
};

let _provider = null;
let _signer = null;
let _dscEngineRead = null;
let _ercRead = {};


// Invalidate caches when wallet state changes
function resetContractInteractionState() {
    _provider = null;
    _signer = null;
    _dscEngineRead = null;
    _ercRead = {};
}

// --- Provider (read-only) ---
function getProvider() {
  if (!_provider) {
    _provider = new ethers.BrowserProvider(window.ethereum);
  }
  return _provider;
}

// --- Signer (for writes) ---
async function getSigner() {
  if (!_signer) {
    const provider = getProvider();
    _signer = await provider.getSigner();
  }
  return _signer;
}

// --- Read-only DSCEngine contract ---
function getDscEngineRead() {
  if (!_dscEngineRead) {
    const provider = getProvider();
    _dscEngineRead = new ethers.Contract(DSC_ENGINE_ADDRESS, DSC_ENGINE_ABI, provider);
  }
  return _dscEngineRead;
}

// --- Read-only DSC ---
function getErcRead(name) {
    if (!(name in _ercRead)) {
	const provider = getProvider();
	const {address, abi} = ERC20_CONFIG[name];
	_ercRead[name] = new ethers.Contract(address, abi, provider);
    }
    return _ercRead[name];
}

// --- Write-enabled DSCEngine contract ---
// Always returns a fresh instance with the current signer.
// This is cheap and guarantees the correct account is used.
async function getDscEngineWrite() {
  return new ethers.Contract(DSC_ENGINE_ADDRESS, DSC_ENGINE_ABI, await getSigner());
}

// Read health factor
async function fetchHealthFactor(userAddress) {
  const engine = getDscEngineRead();
  const hf = await engine.getHealthFactor(userAddress);
  return hf;
}

// Get account information
async function fetchAccountInformation(userAddress) {
    const engine = getDscEngineRead();
    return await engine.getAccountInformation(userAddress);
}


// Get ERC balance
async function getErcBalanceOf(name, address) {
    const erc = getErcRead(name);
    return await erc.balanceOf(address);
}

// Get collateral balance deposited in DSCEngine
async function fetchCollateralBalance(tokenAddress, userAddress) {
  const engine = getDscEngineRead();
  return await engine.getCollateralBalanceOfUser(tokenAddress, userAddress);
}

// Get USD value of a given amount of a collateral token
async function fetchUsdValue(tokenAddress, amount) {
  const engine = getDscEngineRead();
  return await engine.getUsdValue(tokenAddress, amount);
}

// Depositing collateral
async function depositCollateral(tokenName, amount) {
    const engine = await getDscEngineWrite();
    // First approve the engine to spend the token
    const config = ERC20_CONFIG[tokenName];
    const token = new ethers.Contract(config.address, config.abi, await getSigner());
    const txApprove = await token.approve(DSC_ENGINE_ADDRESS, amount);
    await txApprove.wait();
    // Then deposit
    const txDeposit = await engine.depositCollateral(config.address, amount);
    await txDeposit.wait();
}
