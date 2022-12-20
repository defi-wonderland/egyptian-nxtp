%lang starknet

from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_lt
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.utils.solidity_commons import msg_sender

// NOTE: Connext's impl also has ProposedOwnableUpgradeable. I won't implement it yet due to cairo's lack of clarity on upgradeability.

// @title ProposedOwnable
// @notice Contract module which provides a basic access control mechanism,
// where there is an account (an owner) that can be granted exclusive access to
// specific functions.
//
// By default, the owner account will be the one that deploys the contract. This
// can later be changed via a two step process:
// 1. Call `proposeOwner`
// 2. Wait out the delay period
// 3. Call `acceptOwner`
//
// @dev This module is used through inheritance. It will make available the
// modifier `onlyOwner`, which can be applied to your functions to restrict
// their use to the owner.
//
// @dev The majority of this code was taken from the openzeppelin Ownable
// contract


// @dev This emits when change in ownership of a contract is proposed.
@event
func OwnershipProposed(proposed_owner: felt) {
}

// @dev This emits when ownership of a contract changes.
@event
func OwnershipTransferred(previous_owner: felt, new_owner: felt) {
}

// @notice Get the address of the owner
// @return owner The address of the owner.
@storage_var
func ProposedOwnable_owner() -> (owner: felt) {
}

// @notice Get the address of the proposed owner
// @return proposed The address of the proposed.
@storage_var
func ProposedOwnable_proposed() -> (proposed: felt) {
}

@storage_var
func ProposedOwnable_proposed_ownership_timestamp() -> (proposed_ownership_timestamp: felt) {
}

const DELAY = 7 * 60 * 60 * 24;

namespace ProposedOwnable {
    // @notice Returns the address of the current owner
    func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
        return ProposedOwnable_owner.read();
    }

    // @notice Returns the address of the proposed owner
    func proposed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (proposed: felt) {
        return ProposedOwnable_proposed.read();
    }

    // TODO: natspec in connext impl is wrong. Add to feedback.
    // TODO: note: connext's impl returns an Uint256, I'm making it a felt here as it's more than enough for a timestamp
    // @notice Returns the timestamp of the proposed owner
    func proposed_ownership_timestamp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (proposed_ownership_timestamp: felt) {
        return ProposedOwnable_proposed_ownership_timestamp.read();
    }

    // TODO: note: connext's impl returns an Uint256, I'm making it a felt here as it's a constant that fits into a felt
    func delay{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (delay: felt) {
        return (delay=DELAY);   
    }

    // @notice Throws if called by any account other than the owner.
    func only_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (owner) = ProposedOwnable_owner.read();
        with_attr error_message("ProposedOwnable__only_owner_notOwner()") {
            assert_not_zero(msg_sender());
            assert owner = msg_sender();
        }
        return ();
    }

    // @notice Throws if called by any account other than the proposed owner.
    func only_proposed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (proposed) = ProposedOwnable_proposed.read();
        with_attr error_message("ProposedOwnable__only_proposed_notProposedOwner") {
            assert_not_zero(msg_sender());
            assert proposed = msg_sender();
        }
        return ();
    }

    // @notice Throws if called by any account other than the proposed owner.
    func ownership_delay_elapsed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (proposed_ownership_timestamp) = ProposedOwnable_proposed_ownership_timestamp.read();
        
        // TODO: check how does this block.timestamp work on starknet to ensure proper behavior
        let (timestamp) = get_block_timestamp();
        let timestamp_diff = timestamp - proposed_ownership_timestamp;
        with_attr error_message("ProposedOwnable__ownership_delay_elapsed_delayNotElapsed()") {
            assert_lt(DELAY, timestamp_diff);
        }
        return ();
    }

    // @notice Indicates if the ownership has been renounced() by
    //         checking if current owner is address(0)
    func renounced{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (has_owner_renounced: felt) {
        let (owner) = ProposedOwnable_owner.read();
        if (owner == 0) {
            return (has_owner_renounced=TRUE);
        }
        return (has_owner_renounced=FALSE);
    }

    // ======== External =========

    // @notice Sets the timestamp for an owner to be proposed, and sets the
    // newly proposed owner as step 1 in a 2-step process
    func propose_new_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(newly_proposed: felt) { 
        // TODO: this should be called on the contract that implements it, not on the library.
        only_owner();
        let (proposed) = ProposedOwnable_proposed.read();
        let (owner) = ProposedOwnable_owner.read();

        // Contract as source of truth
        if (proposed == newly_proposed) {
            with_attr error_message("ProposedOwnable__propose_new_owner_invalidProposal()") {
                assert 0 = newly_proposed;
            }
        }
        
        // Sanity check: reasonable proposal
        with_attr error_message("ProposedOwnable__proposeNewOwner_noOwnershipChange()") {
            let is_owner_same_as_proposed = owner - newly_proposed;
            assert_not_zero(is_owner_same_as_proposed);
        }

        _set_proposed(newly_proposed);

        return ();
    }

    // @notice Renounces ownership of the contract after a delay
    // TODO: in contract, this function uses ownership_delay_elapsed and onlyOwner modifiers
    func renounce_ownership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        // TODO: this should be called on the contract that implements it, not on the library.
        alloc_locals;
        let (proposed_timestamp) = ProposedOwnable_proposed_ownership_timestamp.read();
        with_attr error_message("ProposedOwnable__renounce_ownership_noProposal()") {
            assert_not_zero(proposed_timestamp);
        }
        
        let (proposed) = ProposedOwnable_proposed.read();
        // Require proposed is set to 0
        with_attr error_message("ProposedOwnable__renounce_ownership_invalidProposal()") {
            assert 0 = proposed;
        }

        // Emit event, set new owner, reset timestamp
        _set_owner(0);

        return ();
    }

    // TODO: in contract, this function uses ownership_delay_elapsed and only_proposed modifiers
    func accept_proposed_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        // NOTE: no need to check if _owner == _proposed, because the _proposed
        // is 0-d out and this check is implicitly enforced by modifier

        // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
        // the only time this would happen is if the _proposed was never
        // set (will fail from modifier) or if the owner == _proposed (checked
        // above)

        let (proposed) = ProposedOwnable_proposed.read();
        // Emit event, set new owner, reset timestamp
        _set_owner(proposed);

        return ();
    }

    func _set_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(new_owner: felt) {
        let (old_owner) = ProposedOwnable_owner.read();
        OwnershipTransferred.emit(old_owner, new_owner);
        ProposedOwnable_owner.write(new_owner);
        ProposedOwnable_proposed_ownership_timestamp.write(0);
        ProposedOwnable_proposed.write(0);
        return ();
    }

    func _set_proposed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(newly_proposed: felt) {
        let (timestamp) = get_block_timestamp();
        ProposedOwnable_proposed_ownership_timestamp.write(timestamp);
        ProposedOwnable_proposed.write(newly_proposed);
        OwnershipProposed.emit(newly_proposed);
        return ();
    }
}