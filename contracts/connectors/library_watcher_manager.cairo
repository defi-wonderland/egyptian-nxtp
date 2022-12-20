%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.library_proposed_ownable import ProposedOwnable
from contracts.utils.solidity_commons import msg_sender

// @notice This contract manages a set of watchers. This is meant to be used as a shared resource that contracts can
// inherit to make use of the same watcher set.

// ============ Events ============
@event
func WatcherAdded(watcher: felt) {
}

@event
func WatcherRemoved(watcher: felt) {
}

// ============ Properties ============
@storage_var
func WatcherManager_is_watcher(watcher: felt) -> (is_watcher: felt) {
}

namespace WatcherManager {
    // ============ Constructor ============
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        return ProposedOwnable._set_owner(msg_sender());
    }

    // ============ Getters ============
    func is_watcher{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_watcher: felt) -> (is_watcher: felt) {
        return WatcherManager_is_watcher.read(_watcher);
    }

    // ============ Admin fns ============
    // @dev Owner can enroll a watcher (abilities are defined by inheriting contracts)
    //TODO: onlyOwner in the contract
    func add_watcher{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_watcher: felt) {
        let (is_watcher) = WatcherManager_is_watcher.read(_watcher);
        with_attr error_message("already watcher") {
            assert FALSE = is_watcher;
        }
        WatcherManager_is_watcher.write(_watcher, TRUE);
        WatcherAdded.emit(_watcher);
        return ();
    }

    // @dev Owner can unenroll a watcher (abilities are defined by inheriting contracts)
    //TODO: onlyOwner in the contract
    func remove_watcher{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_watcher: felt) {
        let (is_watcher) = WatcherManager_is_watcher.read(_watcher);
        with_attr error_message("!exist") {
            assert TRUE = is_watcher;
        }
        WatcherManager_is_watcher.write(_watcher, FALSE);
        WatcherRemoved.emit(_watcher);
        return ();
    }

    // TODO: add --> onlyOwner, in contract or here?
    // @notice Remove ability to renounce ownership
    // @dev Renounce ownership should be impossible as long as only the owner
    // is able to unpause the contracts. You can still propose `address(0)`,
    // but it will never be accepted.
    func renounce_ownership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        // TODO: complete logic if needed in the contracts that inherit from this
        return ();
    }
}


