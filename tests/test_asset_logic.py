from copyreg import constructor

import pytest
from starkware.starknet.testing.starknet import Starknet
from nile.utils import (
    to_uint, add_uint, sub_uint, str_to_felt, MAX_UINT256, ZERO_ADDRESS,
    INVALID_UINT256, TRUE, assert_revert
)
from signers import MockSigner
from utils import get_contract_class, cached_contract, State, Account

# testing vars

# mock signer
signer = MockSigner(9999999999999)


# constants
NAME = str_to_felt("TKN")
SYMBOL = str_to_felt("MCK")
DECIMALS = 18
RECIPIENT = 123
INIT_SUPPLY = to_uint(1000)
RANDOM_FELT = 100
AMOUNT = to_uint(200)
MORE_THAN_APPROVED = to_uint(201)
UINT_ONE = to_uint(1)
UINT_ZERO = to_uint(0)
OUT_OF_BOUNDS_UINT = (2 ** 128 & ((1 << 128)), 2 ** 128 >> 128)
TOKEN_ID_FOR_TEST_DOMAIN_NOT_0 = 1, UINT_ONE
TOKEN_ID_FOR_TEST_DOMAIN_0 = 0, UINT_ONE
EMPTY_TOKEN_ID_FOR_TEST = 0, UINT_ZERO
RANDOM_TOKEN_ADDRESS = 10

@pytest.fixture(scope='module')
def contract_classes():
    account_cls = Account.get_class
    erc20_cls = get_contract_class('mock_erc20')

    return account_cls, erc20_cls

# TODO: find a way to remove this. Deploying erc20_fee_on_transfer on the test for example. Ran into issues doing that though.
@pytest.fixture
async def contract_factory_extended(contract_classes):
    account_cls, erc20_cls = contract_classes
    erc20_fee_on_transfer_cls = get_contract_class('mock_erc20_fee_on_transfer')
    starknet = await State.init()
    account1 = await Account.deploy(signer.public_key)
    account2 = await Account.deploy(signer.public_key)
    asset_logic = await starknet.deploy("contracts/for-test/asset_logic_for_test.cairo")
    erc20 = await starknet.deploy(
        contract_class=erc20_cls,
        constructor_calldata=[
            NAME,
            SYMBOL,
            DECIMALS,
            *INIT_SUPPLY,
            account1.contract_address,
        ]
    )
    erc20_fee_on_transfer = await starknet.deploy(
        contract_class=erc20_fee_on_transfer_cls,
        constructor_calldata=[
            NAME,
            SYMBOL,
            DECIMALS,
            *INIT_SUPPLY,
            account1.contract_address,
        ]
    )
    _state = starknet.state.copy()
    account1 = cached_contract(_state, account_cls, account1)
    account2 = cached_contract(_state, account_cls, account2)
    erc20 = cached_contract(_state, erc20_cls, erc20)
    return (erc20, erc20_fee_on_transfer, asset_logic, account1, account2,)

@pytest.fixture
async def contract_factory(contract_classes):
    account_cls, erc20_cls = contract_classes
    starknet = await State.init()
    account1 = await Account.deploy(signer.public_key)
    account2 = await Account.deploy(signer.public_key)
    asset_logic = await starknet.deploy("contracts/for-test/asset_logic_for_test.cairo")
    erc20 = await starknet.deploy(
        contract_class=erc20_cls,
        constructor_calldata=[
            NAME,
            SYMBOL,
            DECIMALS,
            *INIT_SUPPLY,
            account1.contract_address,
        ]
    )
    _state = starknet.state.copy()
    account1 = cached_contract(_state, account_cls, account1)
    account2 = cached_contract(_state, account_cls, account2)
    erc20 = cached_contract(_state, erc20_cls, erc20)
    return (erc20, asset_logic, account1, account2)

@pytest.fixture
async def minimum_contract_factory():
    starknet = await Starknet.empty()
    asset_logic = await starknet.deploy("contracts/for-test/asset_logic_for_test.cairo")
    return asset_logic

# ###################################################
#             handle_incoming_asset                 #
# ###################################################

@pytest.mark.asyncio
async def test_handle_incoming_asset_should_transfer_correctly(contract_factory):
    """Test ensures that, given the correct parameters, handle_incoming_asset works correctly.
       It checks the balance of asset_logic before the asset is transferred and afterwards to ensure proper accountability.
       It also does a previous approve to asset_logic contract before calling handle_incoming_asset. 
    """
    erc20, asset_logic, account, _  = await contract_factory
    execution = await erc20.balanceOf(asset_logic.contract_address).execute()
    # The Uint value can be obtained through the index zero of the result.
    # The result without indexing looks like this: `balanceOf_return_type(balance=Uint256(low=0, high=0))`
    assert execution.result[0] == UINT_ZERO

    await signer.send_transaction(
        account, erc20.contract_address, 'approve', [
            asset_logic.contract_address,
            *AMOUNT
        ]
    )

    await signer.send_transaction(
        account, asset_logic.contract_address, 'handle_incoming_asset', [
            erc20.contract_address,
            *AMOUNT
        ]
    )

    execution = await erc20.balanceOf(asset_logic.contract_address).execute()
    assert execution.result[0] == AMOUNT

@pytest.mark.asyncio
async def test_handle_incoming_asset_should_return_early(contract_factory):
    """Test ensures that when amount is zero, handle_incoming_asset returns early and no transfer are executed.
       To do this, it checks the balance of asset_logic before handle_incoming_asset is called and afterwards to ensure nothing was transferred.
       It also does a previous approve to asset_logic contract before calling handle_incoming_asset.
    """
    erc20, asset_logic, account, _  = await contract_factory
    execution = await erc20.balanceOf(asset_logic.contract_address).execute()
    # The Uint value can be obtained through the index zero of the result.
    # The result without indexing looks like this: `balanceOf_return_type(balance=Uint256(low=0, high=0))`
    assert execution.result[0] == UINT_ZERO

    await signer.send_transaction(
        account, erc20.contract_address, 'approve', [
            asset_logic.contract_address,
            *AMOUNT
        ]
    )

    await signer.send_transaction(
        account, asset_logic.contract_address, 'handle_incoming_asset', [
            erc20.contract_address,
            *UINT_ZERO
        ]
    )

    execution = await erc20.balanceOf(asset_logic.contract_address).execute()
    assert execution.result[0] == UINT_ZERO

@pytest.mark.asyncio
async def test_handle_incoming_asset_should_revert_wrong_uint(contract_factory):
    """Test ensures that when the amount passed is not a valid uint, handle_incoming_asset reverts.
    """
    erc20, asset_logic, account, _  = await contract_factory

    await assert_revert(signer.send_transaction(
        account, asset_logic.contract_address, 'handle_incoming_asset', [
            erc20.contract_address,
            *OUT_OF_BOUNDS_UINT
        ]
    ), reverted_with="AssetLogic_handleIncomingAsset_invalidUint256__amount()")

@pytest.mark.asyncio
async def test_handle_incoming_asset_should_revert_if_asset_address_zero(contract_factory):
    """Test ensures that when the asset passed is 0, handle_incoming_asset reverts.
    """
    _, asset_logic, account, _  = await contract_factory

    await assert_revert(signer.send_transaction(
        account, asset_logic.contract_address, 'handle_incoming_asset', [
            0,
            *AMOUNT
        ]
    ), reverted_with="AssetLogic__handleIncomingAsset_nativeAssetNotSupported()")

@pytest.mark.asyncio
async def test_handle_incoming_asset_should_revert_if_token_takes_fee_on_transfer(contract_factory_extended):
    """Test ensures that when the token takes a fee on trasfer, handle_incoming_asset reverts.
    """
    _, erc20_fee_on_transfer, asset_logic, account, _  = await contract_factory_extended

    await signer.send_transaction(
        account, erc20_fee_on_transfer.contract_address, 'approve', [
            asset_logic.contract_address,
            *AMOUNT
        ]
    )

    await assert_revert(signer.send_transaction(
        account, asset_logic.contract_address, 'handle_incoming_asset', [
            erc20_fee_on_transfer.contract_address,
            *AMOUNT
        ]
    ), reverted_with="AssetLogic__handleIncomingAsset_feeOnTransferNotSupported()")


#####################################################
#             handle_outgoing_asset                #
#####################################################
@pytest.mark.asyncio
async def test_handle_outgoing_asset_should_transfer_correctly(contract_factory):
    """Test ensures that, given the correct parameters, handle_outgoing_asset works correctly."""
    erc20, asset_logic, account, _  = await contract_factory

    # approve asset_logic to use signer's funds
    await signer.send_transaction(
        account, erc20.contract_address, 'approve', [
            asset_logic.contract_address,
            *AMOUNT
        ]
    )

    # call handle_incoming_asset which transfers the funds to asset_logic
    await signer.send_transaction(
        account, asset_logic.contract_address, 'handle_incoming_asset', [
            erc20.contract_address,
            *AMOUNT
        ]
    )

    execution = await erc20.balanceOf(account.contract_address).execute()
    assert execution.result[0] == sub_uint(INIT_SUPPLY, AMOUNT)

        # call handle_incoming_asset which transfers the funds to asset_logic
    await signer.send_transaction(
        account, asset_logic.contract_address, 'handle_outgoing_asset', [
            erc20.contract_address,
            account.contract_address,
            *AMOUNT
        ]
    )

    execution = await erc20.balanceOf(account.contract_address).execute()
    assert execution.result[0] == INIT_SUPPLY

@pytest.mark.asyncio
async def test_handle_outgoing_asset_should_return_early(contract_factory):
    """Test ensures that when amount is zero, handle_outgoing_asset returns early and no transfer are executed."""
    erc20, asset_logic, account, _  = await contract_factory

    await signer.send_transaction(
        account, erc20.contract_address, 'approve', [
            asset_logic.contract_address,
            *AMOUNT
        ]
    )

    await signer.send_transaction(
        account, asset_logic.contract_address, 'handle_incoming_asset', [
            erc20.contract_address,
            *AMOUNT
        ]
    )

    await signer.send_transaction(
        account, asset_logic.contract_address, 'handle_outgoing_asset', [
            erc20.contract_address,
            account.contract_address,
            *UINT_ZERO
        ]
    )

    execution = await erc20.balanceOf(asset_logic.contract_address).execute()
    assert execution.result[0] == AMOUNT

@pytest.mark.asyncio
async def test_handle_outgoing_asset_should_revert_wrong_uint(contract_factory):
    """Test ensures that when the amount passed is not a valid uint, handle_outgoing_asset reverts."""
    erc20, asset_logic, account, _  = await contract_factory

    await assert_revert(signer.send_transaction(
        account, asset_logic.contract_address, 'handle_outgoing_asset', [
            erc20.contract_address,
            account.contract_address,
            *OUT_OF_BOUNDS_UINT
        ]
    ), reverted_with="AssetLogic_handleOutgoingAsset_invalidUint256__amount()")

@pytest.mark.asyncio
async def test_handle_outgoing_asset_should_revert_if_asset_address_zero(contract_factory):
    """Test ensures that when the asset passed is 0, handle_outgoing_asset reverts."""
    _, asset_logic, account, _  = await contract_factory

    await assert_revert(signer.send_transaction(
        account, asset_logic.contract_address, 'handle_outgoing_asset', [
            0,
            account.contract_address,
            *AMOUNT
        ]
    ), reverted_with="AssetLogic__handleOutgoingAsset_notNative()")

#####################################################
#             get_canonical_token_id                #
#####################################################

@pytest.mark.asyncio
async def test_get_canonical_token_id_candidate_is_zero(minimum_contract_factory):
    """If candidate is zero address, get_canonical_token_id should return empty _canonical"""
    asset_logic = await minimum_contract_factory

    execution = await asset_logic.get_canonical_token_id(ZERO_ADDRESS, TOKEN_ID_FOR_TEST_DOMAIN_NOT_0).execute()

    assert execution.result[0] == EMPTY_TOKEN_ID_FOR_TEST

@pytest.mark.asyncio
async def test_get_canonical_token_id_storage_domain_not_zero(minimum_contract_factory):
    """If candidate is not zero and storage.domain is 0 get_canonical_token_id should return storage"""
    asset_logic = await minimum_contract_factory

    execution = await asset_logic.get_canonical_token_id(1, TOKEN_ID_FOR_TEST_DOMAIN_NOT_0).execute()

    assert execution.result[0] == TOKEN_ID_FOR_TEST_DOMAIN_NOT_0

# TODO: can't truly test this due to origin_local being hardcored to return FALSE.
#       better to wait for the proper implementation instead of creating a fake test
# @pytest.mark.asyncio
# async def test_get_canonical_token_id_is_origin_local_true(minimum_contract_factory):
#     """If candidate is not zero and storage.domain is 0 and is_local_origin is TRUE, 
#     get_canonical_token_id should return local_canonical"""
#     asset_logic, _ = await minimum_contract_factory


@pytest.mark.asyncio
async def test_get_canonical_token_id_is_origin_local_false(minimum_contract_factory):
    """If candidate is not zero and storage.domain is 0 and is_local_origin is FALSE, 
    get_canonical_token_id should return storage"""
    asset_logic = await minimum_contract_factory

    execution = await asset_logic.get_canonical_token_id(1, TOKEN_ID_FOR_TEST_DOMAIN_0).execute()

    assert execution.result[0] == TOKEN_ID_FOR_TEST_DOMAIN_0

#####################################################
#             get_canonical_token_id                #
#####################################################

@pytest.mark.asyncio
async def test_is_local_origin_returns_false_if_storage_domain_not_zero(minimum_contract_factory):
    """If s.Domain is not 0, is_local_origin returns false"""
    asset_logic = await minimum_contract_factory

    execution = await asset_logic.is_local_origin(RANDOM_TOKEN_ADDRESS, TOKEN_ID_FOR_TEST_DOMAIN_NOT_0).execute()

    assert execution.result[0] == False

# TODO: test will remain commented out as the logic of checking if there's code at address doesnt exist in starknet and need to find a workaround
# @pytest.mark.asyncio
# async def test_is_local_origin_returns_true_if_code_at_address(minimum_contract_factory):
#     """If there's code at the token address and the domain is zero, is_local_origin should return true"""
#     asset_logic, _ = await minimum_contract_factory

#     execution = await asset_logic.is_local_origin(RANDOM_TOKEN_ADDRESS, TOKEN_ID_FOR_TEST_DOMAIN_0).execute()

#     assert execution.result[0] == True

@pytest.mark.asyncio
async def test_is_local_origin_returns_false_if_no_code_at_address(minimum_contract_factory):
    """If there's no code at the token address and the domain is zero, is_local_origin should return false"""
    asset_logic = await minimum_contract_factory

    execution = await asset_logic.is_local_origin(RANDOM_TOKEN_ADDRESS, TOKEN_ID_FOR_TEST_DOMAIN_0).execute()

    assert execution.result[0] == False

#TODO: When the actual logic is implemented

#####################################################
#             get_local_asset                       #
#####################################################

#TODO: When the actual logic is implemented