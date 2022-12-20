%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.connectors.library_connector import Connector
from contracts.connectors.library_hub_connector import HubConnector
from contracts.library_proposed_ownable import ProposedOwnable

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_domain: felt, _mirror_domain: felt, _amb: felt, _root_manager: felt, _mirror_connector: felt) {
    HubConnector.initialize(_domain, _mirror_domain, _amb, _root_manager, _mirror_connector);
    return ();
}

// ================= Connector Getters =================
@view
func domain{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (domain: felt) {
    return Connector.domain();
}

@view
func amb{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (amb: felt) {
    return Connector.amb();
}

@view
func root_manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (root_manager: felt) {
    return Connector.root_manager();
}

@view
func mirror_domain{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (mirror_domain: felt) {
    return Connector.mirror_domain();
}

@view
func mirror_connector{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (mirror_connector: felt) {
    return Connector.mirror_connector();
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

// ================= Connector External Functions ==================
@external
func set_mirror_connector{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_mirror_connector: felt) {
    ProposedOwnable.only_owner();
    Connector.set_mirror_connector(_mirror_connector); 
    return ();
}

@external
func process_message{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_data_arr_len: felt, _data_arr: Uint256*) {
    Connector.only_amb(); 
    Connector.process_message(_data_arr_len, _data_arr);
    return ();
}

@external
func verify_sender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_expected: felt) -> (bool: felt) {
    return Connector.verify_sender(_expected);
}

// TODO: see how to handle the virtual/internal functions (_send_message, _process_message, _verify_sender);

// ================= Proposed Ownable External Functions ==================
@external
func propose_new_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(newly_proposed: felt) {
    ProposedOwnable.only_owner();
    ProposedOwnable.propose_new_owner(newly_proposed);
    return ();
}

@external
func renounce_ownership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ProposedOwnable.only_owner();
    ProposedOwnable.ownership_delay_elapsed();
    ProposedOwnable.renounce_ownership();
    return ();
}

@external
func accept_proposed_owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    ProposedOwnable.only_proposed();
    ProposedOwnable.ownership_delay_elapsed();
    ProposedOwnable.accept_proposed_owner();
    return ();
}

// ================= Hub Connector External Functions ==================
@external
func sendMessage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_data_arr_len: felt, _data_arr: Uint256*, encoded_data_arr_len: felt, encoded_data_arr: Uint256*) {
    Connector.only_root_manager();
    HubConnector.sendMessage(_data_arr_len, _data_arr, encoded_data_arr_len, encoded_data_arr);
    return ();
}

