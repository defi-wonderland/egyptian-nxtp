%lang starknet

from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math import assert_not_equal
from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.security.pausable.library import Pausable
from contracts.interfaces.IWatcherManager import IWatcherManager
from contracts.utils.solidity_commons import msg_sender

// @notice This contract abstracts the functionality of the watcher manager.
// Contracts can inherit this contract to be able to use the watcher manager's shared watcher set.
 
// ============ Events ============
// @notice Emitted when the manager address changes
// @param watcherManager The updated manager
@event
func WatcherManagerChanged(watcher_manager: felt) {
}

// ============ Properties ============
// @notice The `WatcherManager` contract governs the watcher allowlist.
// @dev Multiple clients can share a watcher set using the same manager
@storage_var
func WatcherClient_watcher_manager() -> (watcher_manager: felt) {
}

namespace WatcherClient {

    // ============ Initializer ============
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_watcher_manager: felt) {
        return WatcherClient_watcher_manager.write(_watcher_manager);
    }

    // ============ Modifiers ============
    // @notice Enforces the sender is the watcher
    func only_watcher{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (watcher_manager) = WatcherClient_watcher_manager.read();
        with_attr error_message("!watcher") {
            //TODO: can I assume it will use isWatcher or is_watcher?
            let is_watcher = IWatcherManager.isWatcher(contract_address=watcher_manager, caller=msg_sender());
            assert TRUE = is_watcher;
        }
        return ();
    }

    // ============ Admin fns ============
    // TODO: how to handle onlyOwner -- this function is only owner
    // @notice Owner can enroll a watcher (abilities are defined by inheriting contracts)
    func set_watcher_manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_watcher_manager: felt) {
        let (watcher_manager) = WatcherClient_watcher_manager.read();
        with_attr error_message("already watcher manager") {
            assert_not_equal(watcher_manager, _watcher_manager);
        }
        WatcherClient_watcher_manager.write(_watcher_manager);
        WatcherManagerChanged.emit(_watcher_manager);
    }

    // TODO: add --> onlyOwner, whenPaused in contract or here?
    // @notice Owner can unpause contracts if fraud is detected by watchers
    func unpause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        return Pausable._unpause();
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

    // ============ Watcher fns ============
    // TODO: add --> onylWatcher, whenNotPaused in contract or here?
    // @notice Watchers can pause contracts if fraud is detected
    func pause{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        return Pausable._pause();
    }
}