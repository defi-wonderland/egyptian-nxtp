%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.utils.solidity_commons import address_this

// @notice This is an interface to allow the `Messaging` contract to be used
// as a `XappConnectionManager` on all router contracts.
//
// @dev Each nomad router contract has a `XappConnectionClient`, which references a
// XappConnectionManager to get the `Home` (outbox) and approved `Replica` (inbox)
// instances. At any point the client can replace the manager it's pointing to,
// changing the underlying messaging connection.

// TODO: this contract has as an empty constructor -- prob for inheritance clarity. see if adding makes sense
// TODO: test whether the checks of get_contract_address work well when used in libraries
namespace ConnectorManager {
    func home{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (felt) {
        return address_this();
    }

    func is_replica{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_potential_replica: felt) -> (felt) {
        let is_replica = address_this() - _potential_replica;
        if (is_replica == 0) {
            return TRUE;
        }
        return FALSE;
    }

    func local_domain{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (felt) {
        // TODO: this is a virtual func. Logic will go here not be completed on contract
        // Complete with necessary logic.
        // Return value has to be a uint32 -- add check when logic is decided
        return ();
    }
}