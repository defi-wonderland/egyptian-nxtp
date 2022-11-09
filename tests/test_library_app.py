"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.testing.starknet import Starknet

APP_STORAGE = os.path.join("contracts", "app_storage.cairo")

@pytest.mark.asyncio
async def test_add_routed_transfer():
    """Test routedTransfer_add method."""
    starknet = await Starknet.empty()

    contract = await starknet.deploy(
        source=APP_STORAGE,
    )

    await contract.routedTransfers_add(hash=10, address=123).execute()
    await contract.routedTransfers_add(hash=10, address=456).execute()

    execution_info = await contract.routedTransfers(hash=10).call()
    assert execution_info.result[0] == [123, 456]