%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.connectors.library_watcher_manager import WatcherManager
from contracts.library_proposed_ownable import ProposedOwnable

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    WatcherManager.initialize();
    return ();
}

// ================= WatcherManager External Functions ====================
@external
func add_watcher{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _watcher: felt
) {
    ProposedOwnable.only_owner();
    WatcherManager.add_watcher(_watcher);
    return ();    
}

@external
func remove_watcher{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _watcher: felt
) {
    ProposedOwnable.only_owner();
    WatcherManager.remove_watcher(_watcher);
    return ();    
}

// TODO: best way to handle this? This contract in solidity inherits this virtual function from ProposedOwnable
//       but it also overrides it in the WatcherManager contract with no logic.
@external
func renounce_ownership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ProposedOwnable.only_owner();
    WatcherManager.renounce_ownership();
    return ();
}

// ================= Proposed Ownable External Functions ==================
@external
func propose_new_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(newly_proposed: felt) {
    ProposedOwnable.only_owner();
    ProposedOwnable.propose_new_owner(newly_proposed);
    return ();
}

@external
func accept_proposed_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ProposedOwnable.only_proposed();
    ProposedOwnable.ownership_delay_elapsed();
    ProposedOwnable.accept_proposed_owner();
    return ();
}

// ================== WatcherManager Getters ==================
@view
func is_watcher{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_watcher: felt) -> (is_watcher: felt) {
    return WatcherManager.is_watcher(_watcher);
}

// ================= Proposed Ownable Getters =================
@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
    return ProposedOwnable.owner();
}

@view
func proposed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (proposed: felt) {
    return ProposedOwnable.proposed();
}

@view
func proposed_ownership_timestamp{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (proposed_ownership_timestamp: felt) {
    return ProposedOwnable.proposed_ownership_timestamp();
}

@view
func delay{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (delay: felt) {
    return ProposedOwnable.delay();
}

@view
func renounced{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (has_owner_renounced: felt) {
    return ProposedOwnable.renounced();
}
