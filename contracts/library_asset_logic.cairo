%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IERC20 import IERC20
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_sub, uint256_eq
from starkware.cairo.common.math import split_felt
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero

// NOTE: This library contains half the functions of the actual implementation as
//       it doesn't include functions related to stable swap

namespace AssetLogic {

    // TODO: Placeholder. This should come from AppStorage
    struct TokenId {
        Domain: felt,
        Id: Uint256,
    }
    
    // @notice Handles transferring funds from msg.sender to the Connext contract.
    // @dev Does NOT work with fee-on-transfer tokens: will revert.
    // @param _asset - The address of the ERC20 token to transfer.
    // @param _amount - The specified amount to transfer.
    func handle_incoming_asset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_asset: felt, _amount: Uint256) {
        alloc_locals;
        // TODO: this may not be needed. The amount is checked on ERC20 transferFrom and approve. Remove test if this check is removed.
        with_attr error_message("AssetLogic_handleIncomingAsset_invalidUint256__amount()"){
            uint256_check(_amount);
        }

        // Sanity check: if amount is 0, do nothing.
        //TODO: better way to do this?
        let amount_zero = Uint256(0,0);
        let (is_amount_zero) = uint256_eq(_amount, amount_zero);
        
        if (is_amount_zero == TRUE) {
            return ();
        }

        // Sanity check: asset address is not zero.
        with_attr error_message("AssetLogic__handleIncomingAsset_nativeAssetNotSupported()"){
            assert_not_zero(_asset);
        }

        let (this_contract_address) = get_contract_address();
        let (caller_address) = get_caller_address();

        // Record starting amount to validate correct amount is transferred.
        // TODO: can I assume this Uint256 will actually be a Uint256, or should I add a check
        let (starting) = IERC20.balanceOf(contract_address=_asset, account=this_contract_address);

        // Transfer asset to contract.
        // TODO: using normal transferFrom as safeTransfer has not been implemented yet
        let (success) = IERC20.transferFrom(contract_address=_asset, sender=caller_address, recipient=this_contract_address, amount=_amount);

        // Revert if transfer failed.
        // TODO: This may be a redundant check. An erc20 with a trasnfer that returns false or returns nothing on success, will revert.
        //       And we are later checking that the balances post-transfer are correct. Implement a test if it stays with a modifier erc20. 
        with_attr error_message("AssetLogic__handleIncomingAsset_transferFromFailed()"){
            assert success = TRUE;
        }

        // Ensure correct amount was transferred (i.e. this was not a fee-on-transfer token).
        // TODO: can I assume this Uint256 will actually be a Uint256, or should I add a check
        let (local balance_after_transfer) = IERC20.balanceOf(contract_address=_asset, account=this_contract_address);
        let (balance_delta) = uint256_sub(balance_after_transfer, starting);
        // TODO: do I have to compare .low and .high or this general comparison works?
        with_attr error_message("AssetLogic__handleIncomingAsset_feeOnTransferNotSupported()"){
            let (balances_are_equal) = uint256_eq(balance_delta, _amount);
            assert balances_are_equal = TRUE;
        }

        return ();
    }

    // @notice Handles transferring funds from the Connext contract to msg.sender.
    // @param _asset - The address of the ERC20 token to transfer.
    // @param _to - The recipient address that will receive the funds.
    // @param _amount - The amount to withdraw from contract.
    func handle_outgoing_asset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_asset: felt, _to: felt, _amount: Uint256) {
        with_attr error_message("AssetLogic_handleOutgoingAsset_invalidUint256__amount()"){
            uint256_check(_amount);
        }

        // Sanity check: if amount is 0, do nothing.
        //TODO: better way to do this?
        let amount_zero = Uint256(0,0);
        let (is_amount_zero) = uint256_eq(_amount, amount_zero);

        if (is_amount_zero == TRUE) {
                return ();
        }

        // Sanity check: asset address is not zero.
        with_attr error_message("AssetLogic__handleOutgoingAsset_notNative()"){
            assert_not_zero(_asset);
        }

        // Transfer ERC20 asset to target recipient.
        // TODO: using normal transferFrom as safeTransfer has not been implemented yet
        let (success) = IERC20.transfer(contract_address=_asset, recipient=_to, amount=_amount);

        // Revert if transfer failed.
        // TODO: This may be a redundant check. An erc20 with a trasnfer that returns false or returns nothing on success, will revert.
        //       And we are later checking that the balances post-transfer are correct. Implement a test if it stays with a modifier erc20. 
        with_attr error_message("AssetLogic__handleOutgoingAsset_transferFromFailed()"){
            assert success = TRUE;
        }

        return ();
    }


    // @notice Gets the canonical information for a given candidate.
    // @dev First checks the `address(0)` convention, then checks if the asset given is the
    // adopted asset, then calculates the local address.
    // @return TokenId The canonical token ID information for the given candidate.
    // TODO: parameter types are wrong to simplify. _canonical should be of type TokenId
    func get_canonical_token_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_candidate: felt, s: TokenId) -> (canonical: TokenId) {
        //TODO: reordered the original impl a bit to avoid compiling issues. test thoroughly. 
        // If candidate is address(0), return an empty `_canonical`.
        // TODO: does this work? _candidate != address(0)
        if (_candidate == 0) {
            // TODO: not sure if this is the correct way of initializing an empty struct. Need to check/run tests.
            let empty_canonical: TokenId = TokenId(0, Uint256(0,0));
            return (canonical=empty_canonical);
        }
        // Check to see if candidate is an adopted asset.
        // TODO: true logic: _canonical = s.adoptedToCanonical[_candidate];
        let storage_canonical: TokenId = s; // PLACEHOLDER LOGIC
        if (storage_canonical.Domain != 0) {
            // Candidate is an adopted asset, return canonical info.
            return (canonical=s);
        }

        // Candidate was not adopted; it could be the local address.
        // IF this domain is the canonical domain, then the local == canonical.
        // Otherwise, it will be the representation asset.
        let is_origin_local: felt = is_local_origin(_candidate, s); //TODO: placeholder. is_local_origin logic is flawed just yet

        if (is_origin_local == TRUE) {
            // The token originates on this domain, canonical information is the information
            // of the candidate
            let (high, low) = split_felt(_candidate);
            let _candidate_as_uint: Uint256 = Uint256(low, high); 
            let local_canonical: TokenId = TokenId(s.Domain, _candidate_as_uint); //TODO: check. Real logic is TypeCasts.addressToBytes32(_candidate);
            return (canonical=local_canonical);
        } 
        return (canonical=s); // TODO: placeholder. Actual logic: s.representationToCanonical[_candidate];
    }

    // @notice Determine if token is of local origin (i.e. it is a locally originating contract,
    // and NOT a token deployed by the bridge).
    // @param s AppStorage instance.
    // @return bool true if token is locally originating, false otherwise.\
    // TODO: param types are wrong to facilitate 
    func is_local_origin(_token: felt, s: TokenId) -> (bool: felt) {
         // If the token contract WAS deployed by the bridge, it will be stored in this mapping.
         // If so, the token is NOT of local origin.
         if (s.Domain != 0) {
             return(bool=FALSE);
         }
         // If the contract was NOT deployed by the bridge, but the contract does exist, then it
         // IS of local origin. Returns true if code exists at `_addr`.
         let _code_size = 0; // TODO: Placeholder. Real logic is <look_at_contract>
         if (_code_size != 0) {
             return (bool=TRUE);
         }
         return (bool=FALSE);
    }

    // @notice Get the local asset address for a given canonical key, id, and domain.
    // @param _key Canonical hash.
    // @param _id Canonical ID.
    // @param _domain Canonical domain.
    // @param s AppStorage instance.
    // @return address of the the local asset.
    // TODO: param types are wrong to facilitate 
    func get_local_asset(_key: Uint256, _id: Uint256, _domain: felt, s: TokenId) -> (address: felt) {
         if (_domain == s.Domain) {
             // Token is of local origin
             return (address=_domain); //TODO: Placeholder Logic 
         }
         // Token is a representation of a token of remote origin
         return (address=s.Domain); //TODO: Placeholder Logic
    }

    // @notice Calculates the hash of canonical ID and domain.
    // @dev This hash is used as the key for many asset-related mappings.
    // @param _id Canonical ID.
    // @param _domain Canonical domain.
    // @return bytes32 Canonical hash, used as key for accessing token info from mappings.
    // TODO: param types are wrong to facilitate 
    func calculate_canonical_hash(_id: Uint256, _domain: felt) -> (keccak: Uint256) {
        let _keccak = Uint256(1,2); //TODO: Placeholder Logic
        //Real logic: return keccak256(abi.encode(_id, _domain));
        return (keccak=_keccak); //TODO: Placeholder Logic
    }
}