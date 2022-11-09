%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.library_app_storage import AppStorage

// ============ Constant ============

const _delay = 7 * 24 * 60 * 60;

// ============ Events ============

// @notice Emitted when a new router is added
// @param router - The address of the added router
// @param caller - The account that called the function
@event
func RouterAdded(router: felt, caller: felt) {
}

// @notice Emitted when an existing router is removed
// @param router - The address of the removed router
// @param caller - The account that called the function
@event
func RouterRemoved(router: felt, caller: felt) {
}

// @notice Emitted when the recipient of router is updated
// @param router - The address of the added router
// @param prevRecipient  - The address of the previous recipient of the router
// @param newRecipient  - The address of the new recipient of the router
@event
func RouterRecipientSet(router: felt, prevRecipient: felt, newRecipient: felt) {
}

// @notice Emitted when the owner of router is proposed
// @param router - The address of the added router
// @param prevProposed  - The address of the previous proposed
// @param newProposed  - The address of the new proposed
@event
func RouterOwnerProposed(router: felt, prevProposed: felt, newProposed: felt) {
}

// @notice Emitted when the owner of router is accepted
// @param router - The address of the added router
// @param prevOwner  - The address of the previous owner of the router
// @param newOwner  - The address of the new owner of the router
@event
func RouterOwnerAccepted(router: felt, prevOwner: felt, newOwner: felt) {
}

// @notice Emitted when the maxRoutersPerTransfer variable is updated
// @param maxRoutersPerTransfer - The maxRoutersPerTransfer new value
// @param caller - The account that called the function
@event
func MaxRoutersPerTransferUpdated(maxRoutersPerTransfer: felt, caller: felt) {
}

// @notice Emitted when a router is approved for Portal
// @param router - The address of the approved router
// @param caller - The account that called the function
@event
func LiquidityFeeNumeratorUpdated(liquidityFeeNumerator: felt, caller: felt) {
}

// @notice Emitted when a router is approved for Portal
// @param router - The address of the approved router
// @param caller - The account that called the function
@event
func RouterApprovedForPortal(router: felt, caller: felt) {
}

// @notice Emitted when a router is disapproved for Portal
// @param router - The address of the disapproved router
// @param caller - The account that called the function
@event
func RouterUnapprovedForPortal(router: felt, caller: felt) {
}
// @notice Emitted when a router adds liquidity to the contract
// @param router - The address of the router the funds were credited to
// @param local - The address of the token added (all liquidity held in local asset)
// @param key - The hash of the canonical id and domain
// @param amount - The amount of liquidity added
// @param caller - The account that called the function
@event
func RouterLiquidityAdded(router: felt, _local: felt, key: felt, amount: felt, caller: felt) {
}

// @notice Emitted when a router withdraws liquidity from the contract
// @param router - The router you are removing liquidity from
// @param to - The address the funds were withdrawn to
// @param local - The address of the token withdrawn
// @param amount - The amount of liquidity withdrawn
// @param caller - The account that called the function
@event
func RouterLiquidityRemoved(
    router: felt, to: felt, _local: felt, key: felt, amount: felt, caller: felt
) {
}

namespace Router {

    // Todo: access control (initial owner)
    func setupRouter(router: felt, owner: felt, recipient: felt) {
        //onlyOwnerOrRouter()
        // Sanity check: not empty
        with_attr error_message("RoutersFacet__setupRouter_routerEmpty") {
            assert_not_zero(router);
        }

        // Not already added
        with_attr error_message("RoutersFacet__setupRouter_alreadyAdded") {
            let (approved) = AppStorage.approvedRouters_read(router);
            assert FALSE = approved;
        }

        // Approve router
        AppStorage.approvedRouters_write(router, TRUE);

        // Emit event
        let (caller) = get_caller_address();
        RouterAdded.emit(router, caller);

        // Update routerOwner (zero address possible)
        if (owner == 0) {
            AppStorage.routerOwners_write(router, owner);
            RouterOwnerAccepted.emit(router, 0, owner);
        }

        // Update router recipient
        if (recipient == 0) {
            AppStorage.routerRecipients_write(router, recipient);
            RouterRecipientSet.emit(router, 0, recipient);
        }
    }

    func removeRouter(router: felt) {
        //onlyOwnerOrRouter();

        // Sanity check: not empty
        with_attr error_message("RoutersFacet__setupRouter_routerEmpty") {
            assert_not_zero(router);
        }

        // Sanity check: needs removal
        with_attr error_message("RoutersFacet__removeRouter_notAdded") {
            let (approved) = AppStorage.approvedRouters_read(router);
            assert TRUE = approved;
        }

        // Update mapping
        AppStorage.approvedRouters_write(router, FALSE);

        // Emit event
        let (caller) = get_caller_address();
        RouterRemoved.emit(router, caller);

        // Remove router owner
        let (owner) = AppStorage.routerOwners_read(router);
        if (owner != 0) {
            RouterOwnerAccepted.emit(router, owner, 0);
            AppStorage.routerOwners_write(router, 0);
        }

        // Remove router recipient
        let (recipient) = AppStorage.routerRecipients_read(router);
        if (recipient != 0) {
            RouterRecipientSet.emit(router, recipient, 0);
            AppStorage.routerRecipients_write(router, 0);
        }

        // Clear any proposed ownership changes
        AppStorage.proposedRouterOwners_write(router, 0);
        AppStorage.proposedRouterTimerstamp_write(router, 0);

        // Clear approvedForPortal status.
        AppStorage.approvedForPortalRouters_write(router, 0);
    }
    

    func onlyRouterOwner(router: felt) {
        let (owner) = AppStorage.routerOwners_read(router);

        // if ( !( (owner == address(0) && msg.sender == _router) || owner == msg.sender ))
        with_attr error_message("RoutersFacet__onlyRouterOwner_notRouterOwner") {
            let (sender_address) = get_caller_address();
            let temp = (owner + (sender_address - router)) * (owner - sender_address);
            assert 0 = temp;
        }
        return ();
    }
}