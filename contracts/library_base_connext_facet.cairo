%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_check
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from contracts.library_asset_logic import AssetLogic

//TODO: GENERAL:
// 1- check how collision works in cairo. Are the naming conventions correct?
// 2- can we just use OZ's nonReentrant and onlyOwner?
// 3- can I just use common Bool package instead of having _NOT_ENTERED and _ENTERED?
// 4- remember most packages are placeholders until storageFacet and other facets are ready
// 5- can assertions run into issues if variables we assert are not initialized?
// 6- Check if AssetLogic.TokenId when using it as type initializing the variable works well.
// 7- TokenId should come from LibConnextStorage

// TODO: AppStorage internal s;

// ========== Properties ===========
// TODO: should I use Bool from the common package and remove this?
const _NOT_ENTERED = 1;
const _ENTERED = 2;
const BPS_FEE_DENOMINATOR = 10000;
const MAX_UINT_32_VALUE = 2 ** 32 - 1;

// Contains hash of empty bytes
// TODO: bytes32 internal constant EMPTY_HASH = hex"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";
// Should I separate this into two variables? EMPTY_HASH_LOWER_BITS and EMPTY_HASH_UPPER_BITS or make a non-internal state variable and use Uint256


// ==================================== PLACEHOLDERS ====================================

struct Roles {
    None: felt,
    Admin: felt,
    Watcher: felt,
    Router: felt,
}


// TODO: check naming conventions -- this should also be s._status not a storage variable declared here
@storage_var
func BaseConnextFacet_entered() -> (entered: felt) {
}

// TODO: this should come from LibDiamond owner
@storage_var
func BaseConnextFacet_owner() -> (owner: felt) {
}

// TODO: this should come from Storage proposed
@storage_var
func BaseConnextFacet_proposed() -> (proposed: felt) {
}

// TODO: this should come from Storage roles
@storage_var
func BaseConnextFacet_router(user: felt) -> (role: Roles) {
}

// TODO: this should come from Storage roles
@storage_var
func BaseConnextFacet_watcher(user: felt) -> (role: Roles) {
}

// TODO: this should come from Storage roles
@storage_var
func BaseConnextFacet_admin(user: felt) -> (role: Roles) {
}

// TODO: this should come from Storage paused
@storage_var
func BaseConnextFacet_paused() -> (paused: felt) {
}

// TODO: this should come from Storage _routerWhitelistRemoved
@storage_var
func BaseConnextFacet_routerWhitelistRemoved() -> (bool: felt) {
}

// TODO: this should come from Storage _assetWhitelistRemoved
@storage_var
func BaseConnextFacet_assetWhitelistRemoved() -> (bool: felt) {
}

// TODO: this should come from Storage canonicalToAdopted
// TODO: key should be a bytes32
@storage_var
func BaseConnextFacet_canonicalToAdopted(key: Uint256) -> (address: felt) {
}

// ==================================== PLACEHOLDERS ====================================

namespace BaseConnextFacet {
    // ========== START Own Reentrancy to use same error ===========
    func nonReentrant_start{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        // TODO: this should be s_status
        let (has_entered) = BaseConnextFacet_entered.read();
        with_attr error_message("BaseConnextFacet__nonReentrant_reentrantCall()") {
            assert has_entered = _NOT_ENTERED;
        }
        // TODO: this should be s_status
        BaseConnextFacet_entered.write(_ENTERED);
        return ();
    }

    func nonReentrant_end{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        // TODO: this should be s_status
        BaseConnextFacet_entered.write(_NOT_ENTERED);
        return ();
    }

    // =========== END Own Reentrancy to use same error ============

    // ========== START Own onlyOwner to use same error ===========

    // @notice Throws if called by any account other than the owner.
    func only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        //TODO: remember the owner should come from LibDiamond
        let (owner) = BaseConnextFacet_owner.read();
        let (caller) = get_caller_address();
        with_attr error_message("BaseConnextFacet__onlyOwner_notOwner()") {
            assert_not_zero(caller);
            //TODO: remember the owner should come from LibDiamond
            assert owner = caller;
        }
        return ();
    }
    // =========== END Own onlyOwner to use same error ============


    // @notice Throws if called by any account other than the proposed owner.
    func only_proposed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        //TODO: This should come from s._proposed not a state variable here
        let (proposed) = BaseConnextFacet_proposed.read();
        let (caller) = get_caller_address();
        with_attr error_message("BaseConnextFacet__onlyProposed_notProposedOwner()") {
            //TODO: remember the proposed should come from s._proposed
            assert proposed = caller;
        }
        return ();
    }

    // @notice Throws if called by any account other than the owner and router role.
    func only_owner_or_router{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        // TODO: Should come from libDiamond 
        let (owner) = BaseConnextFacet_owner.read();
        let (caller) = get_caller_address();
        // TODO: this should come from s.roles
        // TODO: how do structs evaluate non matching read? Can it return 0 or something and cause and issue with Roles.admin also mapping to 0? 
        let (caller_role) = BaseConnextFacet_router.read(caller);

        // TODO: test and polish, must be a cleaner way to do this.
        with_attr error_message("BaseConnextFacet__onlyOwnerOrRouter_notOwnerOrRouter()") {
        // TODO: check if there's a bug in here
            if (owner != caller) {
                assert caller_role.Router = Roles.Router;
            }
        }
        return ();
    }

    // @notice Throws if called by any account other than the owner and watcher role.
    func only_owner_or_watcher{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        // TODO: Should come from libDiamond 
        let (owner) = BaseConnextFacet_owner.read();
        let (caller) = get_caller_address();
        // TODO: this should come from s.roles
        // TODO: how do structs evaluate non matching read? Can it return 0 or something and cause and issue with Roles.admin also mapping to 0? 
        let (caller_role) = BaseConnextFacet_watcher.read(caller);

        // TODO: test and polish, must be a cleaner way to do this.
        with_attr error_message("BaseConnextFacet__onlyOwnerOrWatcher_notOwnerOrWatcher()") {
        // TODO: check if there's a bug in here
            if (owner != caller) {
                assert caller_role.Watcher = Roles.Watcher;
            }
        }
        return ();
    }

    // @notice Throws if called by any account other than the owner and admin role.
    func only_owner_or_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        // TODO: Should come from libDiamond 
        let (owner) = BaseConnextFacet_owner.read();
        let (caller) = get_caller_address();
        // TODO: this should come from s.roles
        // TODO: how do structs evaluate non matching read? Can it return 0 or something and cause and issue with Roles.admin also mapping to 0? 
        let (caller_role) = BaseConnextFacet_admin.read(caller);

        // TODO: test and polish, must be a cleaner way to do this.
        with_attr error_message("BaseConnextFacet__onlyOwnerOrAdmin_notOwnerOrAdmin()") {
            // TODO: check if there's a bug in here
            if (owner != caller) {
                assert caller_role.Admin = Roles.Admin;
            }
        }
        return ();
    }

    // @notice Throws if all functionality is paused
    func when_not_paused{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        // TODO: Should come from storage 
        let (is_paused) = BaseConnextFacet_paused.read();
        with_attr error_message("BaseConnextFacet__whenNotPaused_paused()") {
            assert is_paused = FALSE;
        }
        return ();
    }

    // ============ Internal ============

    
    // @notice Indicates if the router whitelist has been removed
    // TODO: can this return Bool type somehow?
    func _is_router_whitelist_removed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (bool: felt) {
        // TODO: this should come from LibDiamond
        let (owner) = BaseConnextFacet_owner.read();
        let (router_whitelist_removed) = BaseConnextFacet_routerWhitelistRemoved.read();

        // TODO: cleaner way?
        // TODO: owner != 0 im not certain this is the right way to check
        // if owner != address(0), return whatever routerWhitelistRemoved evaluates to
        if (owner != 0) {
            // This line asserts that router_whitelist_removed is either 0 or 1;
            // TODO: This check does not exist in the original library, we can remove it if
            // we can ensure router_whitelist_removed can only be 0 or 1; 
            assert router_whitelist_removed = router_whitelist_removed * router_whitelist_removed; 
            return (bool=router_whitelist_removed); //this should be a boolean
        }

        // otherwise, return true
        return (bool=TRUE);
    }

    // @notice Indicates if the asset whitelist has been removed
    // TODO: can this return Bool type somehow?
    func _is_asset_whitelist_removed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (bool: felt) {
        // TODO: this should come from LibDiamond
        let (owner) = BaseConnextFacet_owner.read();
        let (asset_whitelist_removed) = BaseConnextFacet_assetWhitelistRemoved.read();

        // TODO: cleaner way?
        // TODO: owner != 0 im not certain this is the right way to check
        // if owner != address(0), return whatever assetWhitelistRemoved evaluates to
        if (owner != 0) {
            // This line asserts that asset_whitelist_removed is either 0 or 1;
            // TODO: This check does not exist in the original library, we can remove it if
            // we can ensure asset_whitelist_removed can only be 0 or 1; 
            assert asset_whitelist_removed = asset_whitelist_removed * asset_whitelist_removed; 
            return (bool=asset_whitelist_removed); //this should be a boolean
        }

        // otherwise, return true
        return (bool=TRUE);
    }

    // @notice Returns the adopted assets for given canonical information
    // TODO: _key should be a bytes32
    func _get_adopted_asset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_key: Uint256) -> (address: felt) {
        with_attr error_message("BaseConnextFacet__getAdoptedAsset_invalidUint256__key()"){
            uint256_check(_key);
        }
        //TODO: should come from s.canonicalToAdopted
        let (adopted) = BaseConnextFacet_canonicalToAdopted.read(_key);
        with_attr error_message("BaseConnextFacet__getAdoptedAsset_notWhitelisted()") {
            assert_not_zero(adopted);
        }
        return(address=adopted);
    }

    // @notice Calculates a transferId
    // TODO: params should be a TransferInfo struct that comes from LibConnextStorage
    // TODO: transfer_id should be a bytes32
    func _calculate_transfer_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_params: felt) -> (transfer_id: Uint256) {
        // TODO: return keccak256(abi.encode(_params));
        let transfer_id = Uint256(1, 2); // TODO: remove this
        // TODO: maybe this won't be needed
        with_attr error_message("BaseConnextFacet__calculateTransferId_invalidUint256_transfer_id()"){
            uint256_check(transfer_id);
        }
        return (transfer_id=transfer_id); //remove this
    }

    // @notice Internal utility function that combines `_origin` and `_nonce`.
    // @dev Both origin and nonce should be less than 2^32 - 1
    // @param _origin Domain of chain where the transfer originated
    // @param _nonce The unique identifier for the message from origin to destination
    // @return Returns (`_origin` << 32) & `_nonce`
    func _origin_and_nonce{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_origin: felt, _nonce: felt) -> (packed_origin_and_nonce: felt) {
        
        with_attr error_message("BaseConnextFacet__origin_and_nonce_invalidUint32__origin()") {
            // TODO: should use is_le or is_le_felt?
            let is_origin_between_bounds = is_le(_origin, MAX_UINT_32_VALUE);
            assert is_origin_between_bounds = TRUE;
        }

        with_attr error_message("BaseConnextFacet__origin_and_nonce_invalidUint32__nonce()") {
            let is_nonce_between_bounds = is_le(_nonce, MAX_UINT_32_VALUE);
            assert is_nonce_between_bounds = TRUE;
        }
        //TODO: natspec @return is wrong?
        //TODO: research how to do this in cairo. 256 - 64 = 192
        //TODO: need to pack origin in the 64-32th bit, and nonce in the 32-0bit
        //TODO: probably need to add assertions for cases where _origin and _nonce are higher than 32 bits;
        //      and the resulting value is lower than 64bits
        //TODO: actual logic = return (uint64(_origin) << 32) | _nonce; 
        return (packed_origin_and_nonce=1); //TODO: remove this
    }

    func _get_local_asset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_key: Uint256, _id: Uint256, _domain: felt) -> (local_asset: felt) {
        with_attr error_message("BaseConnextFacet__getLocalAsset_invalidUint256__key()"){
            uint256_check(_key);
        }
        with_attr error_message("BaseConnextFacet__getLocalAsset_invalidUint256__id()"){
            uint256_check(_id);
        }

        with_attr error_message("BaseConnextFacet__getLocalAndAdoptedToken_invalidUint32__domain()"){
            let is_domain_between_bounds = is_le(_domain, MAX_UINT_32_VALUE);
            assert is_domain_between_bounds = TRUE;
        }

        let placeholder_s = AssetLogic.TokenId(1,Uint256(1,2)); // TODO: remove when storage is ready

        let (local_asset) = AssetLogic.get_local_asset(_key, _id, _domain, placeholder_s);
        return (local_asset);
    }

    func _get_canonical_token_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_candidate: felt) -> (token_id: AssetLogic.TokenId) {
        let s: TokenId = AssetLogic.TokenId(1, Uint256(1,2)); //TODO: remove then storage is implemented
        let (token_id: AssetLogic.TokenId) = AssetLogic.get_canonical_token_id(_candidate, s);
        return (token_id);
    }

    func _get_local_and_adopted_token{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_key: Uint256, _id: Uint256, _domain: felt) -> (local_token: felt, adopted_token: felt) {
        with_attr error_message("BaseConnextFacet__getLocalAndAdoptedToken_invalidUint256__key()"){
            uint256_check(_key);
        }
        with_attr error_message("BaseConnextFacet__getLocalAndAdoptedToken_invalidUint256__id()"){
            uint256_check(_id);
        }

        with_attr error_message("BaseConnextFacet__getLocalAndAdoptedToken_invalidUint32__domain()"){
            let is_domain_between_bounds = is_le(_domain, MAX_UINT_32_VALUE);
            assert is_domain_between_bounds = TRUE;
        }

        let s: TokenId = AssetLogic.TokenId(1, Uint256(1,2)); //TODO: remove then storage is implemented
        
        let (local_token) = AssetLogic.get_local_asset(_key, _id, _domain, s);
        let (adopted_token) = _get_adopted_asset(_key);
        return (local_token, adopted_token);
    }

    func _is_local_origin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_token: felt) -> (is_local_origin: felt) {
        let s: TokenId = AssetLogic.TokenId(1, Uint256(1,2)); //TODO: remove then storage is implemented
        let (is_local_origin) = AssetLogic.is_local_origin(_token, s);
        // ensure is_local_origin is a boolean
        assert is_local_origin = is_local_origin * is_local_origin;
        return (is_local_origin);
    }

    func _get_approved_canonical_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_candidate: felt) -> (_canonical: felt, _key: Uint256) {
        alloc_locals;
        let (local _canonical: AssetLogic.TokenId) = _get_canonical_token_id(_candidate);
        let _key = AssetLogic.calculate_canonical_hash(_canonical.Id, _canonical.Domain);
        with_attr error_message("BaseConnextFacet__getLocalAndAdoptedToken_invalidUint256__key()"){
            uint256_check(_key);
        }
        // TODO: check if there's a bug in the orig implementation in !_isAssetWhitelistRemoved check
        let (is_asset_removed) = _is_asset_whitelist_removed();
        with_attr error_message("BaseConnextFacet__getApprovedCanonicalId_notWhitelisted()") {
        // TODO: double-check this logic
            if (is_asset_removed == FALSE) {
                // TODO: remove placeholder logic
                assert 1 = TRUE; // Actual Logic: s.approvedAssets(key) = TRUE
            }
        }
        
        return(_canonical, _key);
    }
}
