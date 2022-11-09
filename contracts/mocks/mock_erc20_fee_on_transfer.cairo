%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_sub
from openzeppelin.token.erc20.presets.ERC20 import (
    constructor,
    name,
    symbol,
    totalSupply,
    decimals,
    balanceOf,
    allowance,
    approve,
    increaseAllowance,
    decreaseAllowance
)
from openzeppelin.token.erc20.library import ERC20

@external
func transfer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    recipient: felt, amount: Uint256
) -> (success: felt) {
    let fake_fee = Uint256(1,0);
    let (amount_after_fee) = uint256_sub(amount, fake_fee);  
    return ERC20.transfer(recipient, amount_after_fee);
}

@external
func transferFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    sender: felt, recipient: felt, amount: Uint256
) -> (success: felt) {
    let fake_fee = Uint256(1,0);
    let (amount_after_fee) = uint256_sub(amount, fake_fee);
    return ERC20.transfer_from(sender, recipient, amount_after_fee);
}


