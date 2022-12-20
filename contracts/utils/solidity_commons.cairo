%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
)

func msg_sender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
    let (caller_address: felt) = get_caller_address();
    return caller_address;
}

func address_this{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
    let (contract_address: felt) = get_contract_address();
    return contract_address;
}