%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.alloc import alloc


// @dev This is a storing contract

// ============ Struct ============

struct TokenId {
domain: felt,
id: Uint256,
}

// @notice These are the call parameters that will remain constant between the
// two chains. They are supplied on `xcall` and should be asserted on `execute`
// @property to - The account that receives funds, in the event of a crosschain call,
// will receive funds if the call fails.
//
// @param originDomain - The originating domain (i.e. where `xcall` is called). Must match nomad domain schema
// @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called). Must match nomad domain schema
// @param canonicalDomain - The canonical domain of the asset you are bridging
// @param to - The address you are sending funds (and potentially data) to
// @param delegate - An address who can execute txs on behalf of `to`, in addition to allowing relayers
// @param receiveLocal - If true, will use the local nomad asset on the destination instead of adopted.
// @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
// @param slippage - Slippage user is willing to accept from original amount in expressed in BPS (i.e. if
// a user takes 1% slippage, this is expressed as 1_000)
// @param originSender - The msg.sender of the xcall
// @param bridgedAmt - The amount sent over the bridge (after potential AMM on xcall)
// @param normalizedIn - The amount sent to `xcall`, normalized to 18 decimals
// @param nonce - The nonce on the origin domain used to ensure the transferIds are unique
// @param canonicalId - The unique identifier of the canonical token corresponding to bridge assets
struct CallParams {
originDomain: felt,
destinationDomain: felt,
canonicalDomain: felt,
to: felt,
delegate: felt,
receiveLocal: felt,
callData: felt*,
callData_len: felt,
slippage: felt,
originSender: felt,
bridgedAmt: felt,
normalizedIn: felt,
nonce: felt,
canonicalId: Uint256,
}

// @notice
// @param params - The CallParams. These are consistent across sending and receiving chains.
// @param routers - The routers who you are sending the funds on behalf of.
// @param routerSignatures - Signatures belonging to the routers indicating permission to use funds
// for the signed transfer ID.
// @param sequencer - The sequencer who assigned the router path to this transfer.
// @param sequencerSignature - Signature produced by the sequencer for path assignment accountability
// for the path that was signed.
struct ExecuteArgs {
params: CallParams,
routers: felt*,
router_len: felt,
routerSignatures: felt*,
routerSignatures_len: felt,
sequencer: felt,
sequencerSignature: Uint256*,
sequencerSignature_len: felt,
}

struct ArrayAddress {
    addressArray: felt*,
    addressArray_len: felt,
}

// ============ Mappings ============

// Mapping of whitelisted router addresses
@storage_var
func approvedRouters(address: felt) -> (res: felt) {
}

// TODO: Check, I think it's only for stable swap-> remove
@storage_var
func approvedForPortalRouters(address: felt) -> (res: felt) {
}

// Mapping of router withdraw recipient addresses.
// If set, all liquidity is withdrawn only to this address. Must be set by routerOwner
// (if configured) or the router itself
@storage_var
func routerRecipients(address: felt) -> (res: felt) {
}

// Mapping of router owners
// If set, can update the routerRecipien
@storage_var
func routerOwners(address: felt) -> (res: felt) {
}

// Mapping of proposed router owners
@storage_var
func proposedRouterOwners(address: felt) -> (res: felt) {
}

// Mapping of proposed router owners timestamps
// When accepting a proposed owner, must wait for delay to elapse
@storage_var
func proposedRouterTimerstamp(address: felt) -> (res: felt) {
}

// @notice Mapping holding the AMMs for swapping in and out of local assets.
// @dev Swaps for an adopted asset <> nomad local asset (i.e. POS USDC <> madUSDC on polygon).
// This mapping is keyed on the hash of the canonical id + domain for local asset.
//   @ type mapping(bytes32 => IStableSwap) adoptedToLocalPools;
@storage_var
func adoptedToLocalPools(hash: felt) -> (address: felt) {
}

// @notice Mapping of whitelisted assets on same domain as contract.
// @dev Mapping is keyed on the hash of the canonical id and domain taken from the
// token registry.
// @type mapping(bytes32 => bool) approvedAssets;
@storage_var
func approvedAssets(hash: felt) -> (approved: felt) {
}

// @notice Mapping of adopted to canonical asset information.
// @dev If the adopted asset is the native asset, the keyed address will
// be the wrapped asset address.
// @type mapping(address => TokenId) adoptedToCanonical;
@storage_var
func adoptedToCanonical(address: felt) -> (tokenId: felt) {
}

// @notice Mapping of hash(canonicalId, canonicalDomain) to adopted asset on this domain.
// @dev If the adopted asset is the native asset, the stored address will be the
// wrapped asset address.
// @type mapping(bytes32 => address) canonicalToAdopted;
@storage_var
func canonicalToAdopted(hash: felt) -> (address: felt) {
}

// @notice Mapping to determine if transfer is reconciled.
// @type mapping(bytes32 => bool) reconciledTransfers;
@storage_var
func reconciledTransfers(hash: felt) -> (isReconcilied: felt) {
}


// each individual elt of the array; mapping(hash->address[index])
@storage_var
func routedTransfers_internal(hash: felt, index: felt) -> (address: felt) {
}

// mapping(bytes32=> address array length)
@storage_var
func routedTransfers_arraysLen(hash: felt) -> (array_len: felt) {
}

// @notice Mapping of router to available balance of an asset.
// @dev Routers should always store liquidity that they can expect to receive via the bridge on
// this domain (the nomad local asset).
// @type mapping(address => mapping(address => uint256)) routerBalances;
@storage_var
func routerBalances(routerAddress: felt, assetAddress: felt) -> (balance: felt) {
}

// @notice Mapping of approved relayers
// @dev Send relayer fee if msg.sender is approvedRelayer; otherwise revert.
// @type mapping(address => bool) approvedRelayers;
@storage_var
func approvedRelayers(address: felt) -> (isApproved: felt) {
}

// @notice Stores the relayer fee for a transfer. Updated on origin domain when a user calls xcall or bump.
// @dev This will track all of the relayer fees assigned to a transfer by id, including any bumps made by the relayer.
// @type mapping(bytes32 => uint256) relayerFees;
@storage_var
func relayerFees(hash: felt) -> (fee: felt) {
}

// @notice Stores the relayer of a transfer. Updated on the destination domain when a relayer calls execute
// for transfer.
// @dev When relayer claims, must check that the msg.sender has forwarded transfer.
// @type mapping(bytes32 => address) transferRelayer;
@storage_var
func transferRelayer(hash: felt) -> (relayerAddress: felt) {
}

// @notice Stores a mapping of transfer id to slippage overrides.
// @type mapping(bytes32 => uint256) slippage;
@storage_var
func slippage(hash: felt) -> (slippage: felt) {
}

// @notice Stores a mapping of remote routers keyed on domains.
// @dev Addresses are cast to bytes32.
// This mapping is required because the ConnextHandler now contains the BridgeRouter and must implement
// the remotes interface.
// @type mapping(uint32 => bytes32)
@storage_var
func remotes(domain: felt) -> (address: felt) {
}


// @notice Mapping of approved sequencers
// @dev Sequencer address provided must belong to an approved sequencer in order to call `execute`
// for the fast liquidity route.
// @type mapping(address => bool) approvedSequencers;
@storage_var
func approvedSequencers(address: felt) -> (isApproved: felt) {
}

// ============ Public variables ============

// @type bool
@storage_var 
func initialized() -> (res: felt) {
}

// @type uint
@storage_var 
func LIQUIDITY_FEE_NUMERATOR() -> (res: felt) {
}

// @type address
@storage_var
func relayerFeeRouter() -> (res: felt) {
}

// @notice Nonce for the contract, used to keep unique transfer ids.
// @dev Assigned at first interaction (xcall on origin domain).
// @type uint
@storage_var
func nonce() -> (res: felt) {
}

// @notice The domain this contract exists on.
// @dev Must match the nomad domain, which is distinct from the "chainId".
// @type uint32
@storage_var
func domain() -> (res: felt) {
}

// @notice The local nomad token registry.
// @type address
@storage_var
func tokenRegistry() -> (res: felt) {
}

// @notice The max amount of routers a payment can be routed through.
// @type uint256
@storage_var
func maxRoutersPerTransfer() -> (res: felt) {
}

// @notice The address of the nomad bridge router for this chain.
// @type address
@storage_var
func bridgeRouter() -> (res: felt) {
}

// @type address RouterPermissionsManagerInfo routerPermissionInfo;
@storage_var
func routerPermissionInfo() -> (res: felt) {
}

// @notice Remote connection manager for xapp.
// @type address xAppConnectionManager;
@storage_var
func xAppConnectionManager() -> (res: felt) {
}

// ============ Internal variables ============

// ProposedOwnable
// @type address
@storage_var
func _proposed() -> (res: felt) {
}

// @type uint256 _proposedOwnershipTimestamp;
@storage_var
func _proposedOwnershipTimestamp() -> (res: felt) {
}

// @type bool _routerWhitelistRemoved;
@storage_var
func _routerWhitelistRemoved() -> (res: felt) {
}

// @type uint256 _routerWhitelistTimestamp;
@storage_var
func _routerWhitelistTimestamp() -> (res: felt) {
}

// @type bool _assetWhitelistRemoved;
@storage_var
func _assetWhitelistRemoved() -> (res: felt) {
}

// @type uint256 _assetWhitelistTimestamp;
@storage_var
func _assetWhitelistTimestamp() -> (res: felt) {
}

// @type uint256 _status;
@storage_var
func _reentrancyGuardStatus() -> (res: felt) {
}

// @notice Ownership delay for transferring ownership.
// @type uint256 _ownershipDelay;
@storage_var
func _ownershipDelay() -> (res: felt) {
}

namespace AppStorage {

    // ============ Internal functions ============

    func _createArrayInMem{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, index: felt, address: felt*){
        let (address_value) = routedTransfers_internal.read (hash, index);
        assert [address + index] = address_value;

        // 0-indexed
        if (index == 0) {
            return ();
        }

        return _createArrayInMem(hash, index - 1, address);
    }

    func routedTransfers_internal_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, len: felt, address: felt) {
        routedTransfers_internal.write(hash, len, address);
        return();
    }

    // ============ Getters & Setters ============

    func routedTransfers_arraysLen_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, len: felt) {
        routedTransfers_arraysLen.write(hash, len);
        return();
    }

    func routedTransfers_arraysLen_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (len: felt) {
        let (length) = routedTransfers_arraysLen.read(hash); 
        return (len=length);
    }

    // ====== getters & setters ======
    func approvedRouters_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
        let (val) = approvedRouters.read(address);
        return (res = val);
    }

    func approvedRouters_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
        approvedRouters.write(address, value);
        return ();
    }

    func approvedForPortalRouters_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
        let (res) = approvedForPortalRouters.read(address);
        return (res = res);
    }

    func approvedForPortalRouters_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
        approvedForPortalRouters.write(address, value);
        return ();
    }

    func routerRecipients_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
        let (res) = routerRecipients.read(address);
        return (res = res);
    }

    func routerRecipients_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
        routerRecipients.write(address, value);
        return ();
    }

    func routerOwners_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
        let (res) = routerOwners.read(address);
        return (res = res);
    }

    func routerOwners_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
        routerOwners.write(address, value);
        return ();
    }

    func proposedRouterOwners_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
        let (res) = proposedRouterOwners.read(address);
        return (res = res);
    }

    func proposedRouterOwners_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
        proposedRouterOwners.write(address, value);
        return ();
    }

    func proposedRouterTimerstamp_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (res: felt) {
        let (res) = proposedRouterTimerstamp.read(address);
        return (res = res);
    }

    func proposedRouterTimerstamp_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, value: felt) {
        proposedRouterTimerstamp.write(address, value);
        return ();
    }

    func adoptedToLocalPools_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (address: felt) {
        let (res) = adoptedToLocalPools.read(hash);
        return (address=res);
    }

    func adoptedToLocalPools_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, address: felt) {
        adoptedToLocalPools.write(hash, address);
        return ();
    }

    func approvedAssets_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (approved: felt) {
        let (res) = approvedAssets.read(hash);
        return (approved=res);
    }

    func approvedAssets_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, approved: felt) {
        approvedAssets.write(hash, approved);
        return ();
    }

    func adoptedToCanonical_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (tokenId: felt) {
        let (tokenId) = adoptedToCanonical.read(address);
        return (tokenId = tokenId);
    }

    func adoptedToCanonical_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, tokenId: felt) {
        adoptedToCanonical.write(address, tokenId);
        return ();
    }

    func canonicalToAdopted_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (address: felt) {
        let (address) = canonicalToAdopted.read(hash);
        return (address = address);
    }

    func canonicalToAdopted_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, address: felt) {
        canonicalToAdopted.write(hash, address);
        return ();
    }

    func reconciledTransfers_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (isReconcilied: felt) {
        let (isReconcilied) = reconciledTransfers.read(hash);
        return (isReconcilied = isReconcilied);
    }

    func reconciledTransfers_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, isReconcilied: felt) {
        reconciledTransfers.write(hash, isReconcilied);
        return ();
    }

    func routerBalances_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(routerAddress: felt, assetAddress: felt) -> (balance: felt) {
        let (balance) = routerBalances.read(routerAddress, assetAddress);
        return (balance = balance);
    }

    func routerBalances_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(routerAddress: felt, assetAddress: felt, balance: felt) {
        routerBalances.write(routerAddress, assetAddress, balance);
        return ();
    }
        
    func approvedRelayers_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (isApproved: felt) {
        let (isApproved) = approvedRelayers.read(address);
        return (isApproved = isApproved);
    }

    func approvedRelayers_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, isApproved: felt) {
        approvedRelayers.write(address, isApproved);
        return ();
    }

    func relayerFees_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (fee: felt) {
        let (res) = relayerFees.read(hash);
        return (fee = res);
    }

    func relayerFees_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, fee: felt) {
        relayerFees.write(hash, fee);
        return ();
    }

    func transferRelayer_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (relayerAddress: felt) {
        let (relayerAddress) = transferRelayer.read(hash);
        return (relayerAddress = relayerAddress);
    }

    func transferRelayer_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, relayerAddress: felt) {
        transferRelayer.write(hash, relayerAddress);
        return ();
    }

    func slippage_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt) -> (slippage: felt) {
        let (res) = slippage.read(hash);
        return (slippage = res);
    }

    func slippage_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(hash: felt, slip: felt) {
        slippage.write(hash, slip);
        return ();
    }

    func remotes_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(domain: felt) -> (address: felt) {
        let (address) = remotes.read(domain);
        return (address = address);
    }

    func remotes_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(domain: felt, address: felt) {
        remotes.write(domain, address);
        return ();
    }

    func approvedSequencers_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt) -> (isApproved: felt) {
        let (isApproved) = approvedSequencers.read(address);
        return (isApproved = isApproved);
    }

    func approvedSequencers_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(address: felt, isApproved: felt) {
        approvedSequencers.write(address, isApproved);
        return ();
    }

    func initialized_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
        let (res) = initialized.read();
        return (res = res);
    }

    func initialized_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
        initialized.write(value);
        return ();
    }

    func LIQUIDITY_FEE_NUMERATOR_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
        let (res) = LIQUIDITY_FEE_NUMERATOR.read();
        return (res = res);
    }

    func LIQUIDITY_FEE_NUMERATOR_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
        LIQUIDITY_FEE_NUMERATOR.write(value);
        return ();
    }

    func relayerFeeRouter_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
        let (res) = relayerFeeRouter.read();
        return (res = res);
    }

    func relayerFeeRouter_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
        relayerFeeRouter.write(value);
        return ();
    }

    func nonce_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
        let (res) = nonce.read();
        return (res = res);
    }

    func nonce_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
        nonce.write(value);
        return ();
    }

    func domain_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
        let (res) = domain.read();
        return (res = res);
    }

    func domain_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
        domain.write(value);
        return ();
    }

    func tokenRegistry_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
        let (res) = tokenRegistry.read();
        return (res = res);
    }

    func tokenRegistry_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
        tokenRegistry.write(value);
        return ();
    }

    func maxRoutersPerTransfer_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
        let (res) = maxRoutersPerTransfer.read();
        return (res = res);
    }

    func maxRoutersPerTransfer_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
        maxRoutersPerTransfer.write(value);
        return ();
    }

    func bridgeRouter_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
        let (res) = bridgeRouter.read();
        return (res = res);
    }

    func bridgeRouter_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
        bridgeRouter.write(value);
        return ();
    }

    func routerPermissionInfo_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
        let (res) = routerPermissionInfo.read();
        return (res = res);
    }

    func routerPermissionInfo_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
        routerPermissionInfo.write(value);
        return ();
    }

    func xAppConnectionManager_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (res: felt) {
        let (res) = xAppConnectionManager.read();
        return (res = res);
    }

    func xAppConnectionManager_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(value: felt) {
        xAppConnectionManager.write(value);
        return ();
    }
}