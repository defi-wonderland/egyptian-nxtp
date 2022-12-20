%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.connectors.library_connector import MessageSent, Connector
from starkware.cairo.common.uint256 import Uint256

// @title HubConnector
// @author Connext Labs, Inc.
// @notice This contract implements the messaging functions needed on the hub-side of a given AMB.
// The HubConnector has a limited set of functionality compared to the SpokeConnector, namely that
// it contains no logic to store or prove messages.
//
// @dev This contract should be deployed on the hub-side of an AMB (i.e. on L1), and contracts
// which extend this should implement the virtual functions defined in the BaseConnector class


namespace HubConnector {
    // ============ Initializer ============

    // @notice Creates a new HubConnector instance
    // @dev The connectors are deployed such that there is one on each side of an AMB (i.e.
    // for optimism, there is one connector on optimism and one connector on mainnet)
    // @param _domain The domain this connector lives on
    // @param _mirrorDomain The spoke domain
    // @param _amb The address of the amb on the domain this connector lives on
    // @param _rootManager The address of the RootManager on mainnet
    // @param _mirrorConnector The address of the spoke connector
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_domain: felt, _mirror_domain: felt, _amb: felt, _root_manager: felt, _mirror_connector: felt) {
        Connector.initialize(_domain, _mirror_domain, _amb, _root_manager, _mirror_connector);
        return ();
    }

    // ============ Public fns ============

    // @notice Sends a message over the amb
    // @dev This is called by the root manager *only* on mainnet to propagate the aggregate root
    func sendMessage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_data_arr_len: felt, _data_arr: Uint256*, encoded_data_arr_len: felt, encoded_data_arr: Uint256*) {
        //TODO: check revoked pointers without alloc locals -- msg.sender() also throws revoked pointers issues
        alloc_locals;
        let (caller) = get_caller_address();
        _sendMessage(_data_arr_len, _data_arr, encoded_data_arr_len, encoded_data_arr);
        MessageSent.emit(_data_arr_len, _data_arr, encoded_data_arr_len, encoded_data_arr, caller);
        return ();
    }

    // ============ Internal fns ============

    // TODO: complete with actual impl. this is virtual in solidity
    func _sendMessage{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_data_arr_len: felt, _data_arr: Uint256*, encoded_data_arr_len: felt, encoded_data_arr: Uint256*) {
        //TODO: complete
        return ();
    }

}