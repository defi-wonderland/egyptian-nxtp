%lang starknet

from starkware.cairo.common.uint256 import Uint256

//  @notice Interface for all contracts sending messages originating on their
//  current domain.
// 
//  @dev These are the Home.sol interface methods used by the `Router`
//  and exposed via `home()` on the `XAppConnectionClient`

@contract_interface
namespace IOutbox {
    // TODO: in Connext impl, there's an event here. Due to inheritance not being a part of cairo just yet, I've left it out.
    //       therefore that event must be implemented in any contract that inherits from IOutBox. Ensure this in respective contracts.

    // @notice Dispatch the message it to the destination domain & recipient
    // @dev Format the message, insert its hash into Merkle tree,
    // enqueue the new Merkle root, and emit `Dispatch` event with message information.
    // @param _destination_domain Domain of destination chain
    // @param _recipient_address Address of recipient on destination chain as bytes32
    // @param _message_body_bytes_len Length of the _message_body_bytes array
    // @param _message_body_bytes Pointer to the raw bytes content of message
    // @return leaf bytes32 The leaf added to the tree
    func dispatch(_destination_domain: felt, _recipient_address: Uint256, _message_body_bytes_len: felt, _message_body_bytes: Uint256*) -> (leaf: Uint256) {
    }
}