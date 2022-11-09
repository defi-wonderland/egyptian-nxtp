%lang starknet

//TODO: using this exclusively for test for now. Will change if we need to expose some functions
//      and apply extensibility pattern 
// TODO: functions like handle_outgoing_asset should never be external

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IERC20 import IERC20
from contracts.library_asset_logic import AssetLogic
from starkware.cairo.common.uint256 import Uint256, uint256_check, uint256_sub, uint256_eq
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero

@external
func handle_incoming_asset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_asset: felt, _amount: Uint256) {
    return AssetLogic.handle_incoming_asset(_asset, _amount);
}

@external
func handle_outgoing_asset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_asset: felt, _to: felt, _amount: Uint256) {
    return AssetLogic.handle_outgoing_asset(_asset, _to, _amount);
}

@external
func get_canonical_token_id{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_candidate: felt, s: AssetLogic.TokenId) -> (canonical: AssetLogic.TokenId) {
    let (canonical: AssetLogic.TokenId) = AssetLogic.get_canonical_token_id(_candidate, s);
    return (canonical=canonical);
}

@external
func is_local_origin(_token: felt, s: AssetLogic.TokenId) -> (bool: felt) {
    let (bool: felt) = AssetLogic.is_local_origin(_token, s);
    return (bool=bool);
}

@external
func get_local_asset(_key: Uint256, _id: Uint256, _domain: felt, s: AssetLogic.TokenId) -> (address: felt) {
    let (address: felt) = AssetLogic.get_local_asset(_key, _id, _domain, s);
    return (address=address);
}

@external
func calculate_canonical_hash(_id: Uint256, _domain: felt) -> (keccak: Uint256) {
    let (keccak: Uint256) = AssetLogic.calculate_canonical_hash(_id, _domain);
    return (keccak=keccak);
}