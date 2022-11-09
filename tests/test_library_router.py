"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

from signers import MockSigner
from utils import get_contract_class, cached_contract, State, Account


# ###################################################
#                     test setup                    #
# ###################################################

signer = MockSigner(6942069420)


@pytest.fixture(scope='module')
def contract_classes():
    return (
        Account.get_class,
        get_contract_class('Router'),
    )

@pytest.fixture(scope='module')
async def router_init(contract_classes):
    account_cls, router_cls = contract_classes
    starknet = await State.init()
    router_caller = await Account.deploy(signer.public_key)
    router_facet = await starknet.deploy(
        contract_class=router_cls
        # constructor_calldata=[owner.contract_address]
    )
    not_router_caller = await Account.deploy(signer.public_key)
    return starknet.state, router_facet, router_caller, not_router_caller

@pytest.fixture
def contract_factory(contract_classes, ownable_init):
    account_cls, router_cls = contract_classes
    state, router_facet, router_caller, not_router_caller = ownable_init
    _state = state.copy()
    router_caller = cached_contract(_state, account_cls, router_caller)
    router_facet = cached_contract(_state, router_facet, router_caller)
    not_router_caller = cached_contract(_state, account_cls, not_router_caller)
    return router_facet, router_caller, not_router_caller

@pytest.mark.asyncio
async def test_onlyRouter_pass_if_caller_router(contract_factory):
    """Test only router - pass if sender is the router and no owner"""
    router_facet, router_caller, not_router_caller = contract_factory
    

    await assert_revert(
        signer.send_transaction(not_owner, ownable.contract_address, 'protected_function', []),
        reverted_with="Ownable: caller is not the owner"
    )

    await contract.onlyRouterOwner(router=123).execute()

    execution_info = await contract.routedTransfers(hash=10).call()
    assert execution_info.result[0] == [123, 456]


    #     await assert_revert(
    #     signer.send_transaction(
    #         account1,
    #         accesscontrol.contract_address,
    #         'renounceRole',
    #         [
    #             DEFAULT_ADMIN_ROLE,
    #             account2.contract_address
    #         ]
    #     ),
    #     reverted_with="AccessControl: can only renounce roles for self"
    # )
