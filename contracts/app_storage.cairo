%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc

from contracts.library_app_storage import AppStorage

// @dev This is a storing contract

// ============ External view ============

// @notice Mapping holding router address that provided fast liquidity.
// @type mapping(bytes32 => address[]) routedTransfers;
@external
func routedTransfers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (address_len: felt, address: felt*) {
    alloc_locals;
    let (local address: felt*) = alloc();

    let (local address_len: felt) = AppStorage.routedTransfers_arraysLen_read(hash);
    AppStorage._createArrayInMem(hash, address_len, address);
    return(address_len, address);
}

// ============ External state modifying ============
@external
func routedTransfers_add{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, address: felt) {
    alloc_locals;
    let (local len) = AppStorage.routedTransfers_arraysLen_read(hash);
    AppStorage.routedTransfers_internal_write(hash, len, address);
    AppStorage.routedTransfers_arraysLen_write(hash, len + 1);

    return ();
}

// ============ Getters & Setters ============

// Insert the 2000 getters and setters here...
@external
func routedTransfers_arraysLen_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, len: felt) {
    AppStorage.routedTransfers_arraysLen_write(hash, len);
    return();
}

@external
func routedTransfers_arraysLen_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (len: felt) {
    let (length) = AppStorage.routedTransfers_arraysLen_read(hash); 
    return (len=length);
}

// ====== getters & setters ======
@external
func approvedRouters_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
    let (res) = AppStorage.approvedRouters_read(address);
    return (res = res);
}

@external
func approvedRouters_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
    AppStorage.approvedRouters_write(address, value);
    return ();
}

@external
func approvedForPortalRouters_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
    let (res) = AppStorage.approvedForPortalRouters_read(address);
    return (res = res);
}

@external
func approvedForPortalRouters_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
    AppStorage.approvedForPortalRouters_write(address, value);
    return ();
}

@external
func routerRecipients_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
    let (res) = AppStorage.routerRecipients_read(address);
    return (res = res);
}

@external
func routerRecipients_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
    AppStorage.routerRecipients_write(address, value);
    return ();
}

@external
func routerOwners_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
    let (res) = AppStorage.routerOwners_read(address);
    return (res = res);
}

@external
func routerOwners_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
    AppStorage.routerOwners_write(address, value);
    return ();
}

@external
func proposedRouterOwners_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
    let (res) = AppStorage.proposedRouterOwners_read(address);
    return (res = res);
}

@external
func proposedRouterOwners_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
    AppStorage.proposedRouterOwners_write(address, value);
    return ();
}

@external
func proposedRouterTimerstamp_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
    let (res) = AppStorage.proposedRouterTimerstamp_read(address);
    return (res = res);
}

@external
func proposedRouterTimerstamp_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
    AppStorage.proposedRouterTimerstamp_write(address, value);
    return ();
}

@external
func adoptedToLocalPools_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (address: felt) {
    let (res) = AppStorage.adoptedToLocalPools_read(hash);
    return (address = res);
}

@external
func adoptedToLocalPools_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, address: felt) {
    AppStorage.adoptedToLocalPools_write(hash, address);
    return ();
}

@external
func approvedAssets_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (approved: felt) {
    let (res) = AppStorage.approvedAssets_read(hash);
    return (approved = res);
}

@external
func approvedAssets_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, approved: felt) {
    AppStorage.approvedAssets_write(hash, approved);
    return ();
}

@external
func adoptedToCanonical_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (tokenId: felt) {
    let (res) = AppStorage.adoptedToCanonical_read(address);
    return (tokenId = res);
}

@external
func adoptedToCanonical_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, tokenId: felt) {
    AppStorage.adoptedToCanonical_write(address, tokenId);
    return ();
}

@external
func canonicalToAdopted_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (address: felt) {
    let (res) = AppStorage.canonicalToAdopted_read(hash);
    return (address = res);
}

@external
func canonicalToAdopted_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, address: felt) {
    AppStorage.canonicalToAdopted_write(hash, address);
    return ();
}

@external
func reconciledTransfers_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (isReconcilied: felt) {
    let (res) = AppStorage.reconciledTransfers_read(hash);
    return (isReconcilied = res);
}

@external
func reconciledTransfers_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, isReconcilied: felt) {
    AppStorage.reconciledTransfers_write(hash, isReconcilied);
    return ();
}

@external
func routerBalances_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(routerAddress: felt, assetAddress: felt) -> (balance: felt) {
    let (res) = AppStorage.routerBalances_read(routerAddress, assetAddress);
    return (balance = res);
}

@external
func routerBalances_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(routerAddress: felt, assetAddress: felt, balance: felt) {
    AppStorage.routerBalances_write(routerAddress, assetAddress, balance);
    return ();
}
    
@external
func approvedRelayers_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (isApproved: felt) {
    let (res) = AppStorage.approvedRelayers_read(address);
    return (isApproved = res);
}

@external
func approvedRelayers_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, isApproved: felt) {
    AppStorage.approvedRelayers_write(address, isApproved);
    return ();
}

@external
func relayerFees_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (fee: felt) {
    let (res) = AppStorage.relayerFees_read(hash);
    return (fee = res);
}

@external
func relayerFees_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, fee: felt) {
    AppStorage.relayerFees_write(hash, fee);
    return ();
}

@external
func transferRelayer_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (relayerAddress: felt) {
    let (res) = AppStorage.transferRelayer_read(hash);
    return (relayerAddress = res);
}

@external
func transferRelayer_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, relayerAddress: felt) {
    AppStorage.transferRelayer_write(hash, relayerAddress);
    return ();
}

@external
func slippage_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (slippage: felt) {
    let (res) = AppStorage.slippage_read(hash);
    return (slippage = res);
}

@external
func slippage_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, slippage: felt) {
    AppStorage.slippage_write(hash, slippage);
    return ();
}

@external
func remotes_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(domain: felt) -> (address: felt) {
    let (res) = AppStorage.remotes_read(domain);
    return (address = res);
}

@external
func remotes_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(domain: felt, address: felt) {
    AppStorage.remotes_write(domain, address);
    return ();
}

@external
func approvedSequencers_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (isApproved: felt) {
    let (res) = AppStorage.approvedSequencers_read(address);
    return (isApproved = res);
}

@external
func approvedSequencers_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, isApproved: felt) {
    AppStorage.approvedSequencers_write(address, isApproved);
    return ();
}

@external
func initialized_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = AppStorage.initialized_read();
    return (res = res);
}

@external
func initialized_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
    AppStorage.initialized_write(value);
    return ();
}

@external
func LIQUIDITY_FEE_NUMERATOR_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = AppStorage.LIQUIDITY_FEE_NUMERATOR_read();
    return (res = res);
}

@external
func LIQUIDITY_FEE_NUMERATOR_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
    AppStorage.LIQUIDITY_FEE_NUMERATOR_write(value);
    return ();
}

@external
func relayerFeeRouter_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = AppStorage.relayerFeeRouter_read();
    return (res = res);
}

@external
func relayerFeeRouter_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
    AppStorage.relayerFeeRouter_write(value);
    return ();
}

@external
func nonce_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = AppStorage.nonce_read();
    return (res = res);
}

@external
func nonce_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
    AppStorage.nonce_write(value);
    return ();
}

@external
func domain_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = AppStorage.domain_read();
    return (res = res);
}

@external
func domain_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
    AppStorage.domain_write(value);
    return ();
}

@external
func tokenRegistry_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = AppStorage.tokenRegistry_read();
    return (res = res);
}

@external
func tokenRegistry_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
    AppStorage.tokenRegistry_write(value);
    return ();
}

@external
func maxRoutersPerTransfer_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = AppStorage.maxRoutersPerTransfer_read();
    return (res = res);
}

@external
func maxRoutersPerTransfer_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
    AppStorage.maxRoutersPerTransfer_write(value);
    return ();
}

@external
func bridgeRouter_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = AppStorage.bridgeRouter_read();
    return (res = res);
}

@external
func bridgeRouter_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
    AppStorage.bridgeRouter_write(value);
    return ();
}

@external
func routerPermissionInfo_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = AppStorage.routerPermissionInfo_read();
    return (res = res);
}

@external
func routerPermissionInfo_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
    AppStorage.routerPermissionInfo_write(value);
    return ();
}

@external
func xAppConnectionManager_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
    let (res) = AppStorage.xAppConnectionManager_read();
    return (res = res);
}

@external
func xAppConnectionManager_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
    AppStorage.xAppConnectionManager_write(value);
    return ();
}