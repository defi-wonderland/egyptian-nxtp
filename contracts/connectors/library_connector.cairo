%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.bool import TRUE
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.library_proposed_ownable import ProposedOwnable
from contracts.utils.solidity_commons import msg_sender

// TODO: research if extensibility pattern works well between libraries.
// TODO: change description?

 // @title Connector
 // @author Connext Labs, Inc.
 // @notice This contract has the messaging interface functions used by all connectors.
 //
 // @dev This contract stores information about mirror connectors, but can be used as a
 // base for contracts that do not have a mirror (i.e. the connector handling messaging on
 // mainnet). In this case, the `mirrorConnector`, `MIRROR_DOMAIN`, and `mirrorGas`
 // will be empty
 //
 // @dev If ownership is renounced, this contract will be unable to update its `mirrorConnector`
 // or `mirrorGas`

 // TODO: create constants library
 // ============ Constants ============
 const MAX_UINT_32 = 2 ** 32 - 1;

 // ============ Events ============
 @event
 func NewConnector(domain: felt, mirror_domain: felt, amb: felt, root_manager: felt, mirror_connector: felt) {
 }

 @event
 func MirrorConnectorUpdated(previous: felt, current: felt) {
 }

 // @notice Emitted whenever a message is successfully sent over an AMB
 // @param data_arr_len The len of the data array
 // @param data_arr The contents of the message
 // @param data_arr_len The len of the data used to send the message
 // @param data_arr Data used to send the message; specific to connector
 // @param caller Who called the function (sent the message)

 @event
 func MessageSent(data_arr_len: felt, data_arr: Uint256*, encoded_data_arr_len: felt, encoded_data_arr: Uint256*, caller: felt) {
 }

 // @notice Emitted whenever a message is successfully received over an AMB
 // @param data_arr_len The len of the data array
 // @param data_arr The contents of the message
 // @param caller Who called the function

 @event
 func MessageProcessed(data_arr_len: felt, data_arr: Uint256*, caller: felt) {
 }

  // ============ Public Storage ============
  
  // @notice The domain of this Messaging (i.e. Connector) contract.
  @storage_var
  func Connector_domain() -> (domain: felt) {
  }

  // @notice Address of the AMB on this domain.
  @storage_var
  func Connector_amb() -> (amb: felt) {
  }

  // @notice RootManager contract address.
  @storage_var
  func Connector_root_manager() -> (root_manager: felt) {
  }

  // @notice The domain of the corresponding messaging (i.e. Connector) contract.
  @storage_var
  func Connector_mirror_domain() -> (mirror_domain: felt) {
  }

  // @notice Connector on L2 for L1 connectors, and vice versa.
  @storage_var
  func Connector_mirror_connector() -> (mirror_connector: felt) {
  }
  
  namespace Connector {
    // @notice Errors if the msg.sender is not the registered AMB
    func only_amb{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (amb) = Connector_amb.read();
        // TODO: errors are abit inconsistent across connext contracts. some use require others custom erros.
        //       may be worth adding to the feedback
        with_attr error_message("!AMB") {
            // TODO: if there's no edge-case where caller can be the zero address, the assertion can be 
            //       removed.
            assert_not_zero(msg_sender());
            assert 0 = msg_sender() - amb;
        }

        return ();
    }

    // @notice Errors if the msg.sender is not the registered ROOT_MANAGER
    func only_root_manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        // NOTE: RootManager will be zero address for spoke connectors.
        // Only root manager can dispatch a message to spokes/L2s via the hub connector.
        let (root_manager) = Connector_root_manager.read();
        // TODO: errors are abit inconsistent across connext contracts. some use require others custom erros.
        //       may be worth adding to the feedback
        with_attr error_message("!rootManager") {
            // TODO: if there's no edge-case where caller can be the zero address, the assertion can be 
            //       removed.
            assert_not_zero(msg_sender());
            assert 0 = msg_sender() - root_manager;
        }

        return ();       
    }

    // ============ Initializer ============

    // @notice Creates a new HubConnector instance
    // @dev The connectors are deployed such that there is one on each side of an AMB (i.e.
    // for optimism, there is one connector on optimism and one connector on mainnet)
    // @param _domain The domain this connector lives on
    // @param _mirrorDomain The spoke domain
    // @param _amb The address of the amb on the domain this connector lives on
    // @param _rootManager The address of the RootManager on mainnet
    // @param _mirrorConnector The address of the spoke connector
    // TODO: actual constructor has ProposedOwnable empty constructor --> add here or in contraact? Also add to ProposedOwnable (it's an empty constructor)
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_domain: felt, _mirror_domain: felt, _amb: felt, _root_manager: felt, _mirror_connector: felt) {
        // Sanity checks
        // TODO: standarize error messages
        // TODO: check if moving these checks to private functions would work
        with_attr error_message("Domain_Not_Uint32()") {
            let is_domain_uint_32 = is_le(_domain, MAX_UINT_32);
            assert is_domain_uint_32 = TRUE;
        }

        with_attr error_message("MirrorDomain_Not_Uint32()") {
            let is_mirror_domain_uint_32 = is_le(_mirror_domain, MAX_UINT_32);
            assert is_mirror_domain_uint_32 = TRUE;
        }

        with_attr error_message("empty domain"){
            assert_not_zero(_domain);
        }

        with_attr error_message("empty rootManager"){
            assert_not_zero(_root_manager);
        }

        // see note at top of contract on why the mirror values are not sanity checked
        
        //TODO: should this be here or in the contract?
        ProposedOwnable._set_owner(msg_sender());
        
        // set immutables
        Connector_domain.write(_domain);
        Connector_amb.write(_amb);
        Connector_root_manager.write(_root_manager);
        Connector_mirror_domain.write(_mirror_domain);

        if (_mirror_connector != 0) {
           _set_mirror_connector(_mirror_connector);
        }

        NewConnector.emit(_domain, _mirror_domain, _amb, _root_manager, _mirror_connector);
        return ();
    }

    // ============ Receivable ============
    // TODO: research if there's an equivalent to receive() in starknet -> this func implements this


    // ============ Admin Functions ============

    // TODO: this is onlyOwner --> if we follow nethermind, that should be called on the contract not here
    // @notice Sets the address of the l2Connector for this domain
    func set_mirror_connector{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_mirror_connector: felt) {
        _set_mirror_connector(_mirror_connector);
        return ();
    }

    // ============ Public Functions ============
    //TODO: This is only callable by amb (uses OnlyAmb modif). Implement it in contract
    // @notice Processes a message received by an AMB
    // @dev This is called by AMBs to process messages originating from mirror connector
    func process_message{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_data_arr_len: felt, _data_arr: Uint256*) {
        // TODO: check why references are being revoked and if there's a better way to handle it without alloc_locals
        alloc_locals;
        let (caller) = get_caller_address();
        _process_message(_data_arr_len, _data_arr);
        MessageProcessed.emit(_data_arr_len, _data_arr, caller);
        return ();
    }

    // TODO: should this be permissioned?
    // @notice Checks the cross domain sender for a given address
    func verify_sender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_expected: felt) -> (bool: felt) {
        let (res) = _verify_sender(_expected);
        return (bool=res);
    }
    
    // ============ Virtual Functions ============
    //TODO: Implement logic. In connext impl, these are virtual. As we will have only one contract
    //      These functions can be implemented here
    // @notice This function is used by the Connext contract on the l2 domain to send a message to the
    // l1 domain (i.e. called by Connext on optimism to send a message to mainnet with roots)
    func _send_message{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_data_arr_len: felt, _data_arr: Uint256*) {
        // TODO: complete
        return ();
    }

    //TODO: Implement logic. In connext impl, these are virtual. As we will have only one contract
    //      These functions can be implemented here
    // @notice This function is used by the AMBs to handle incoming messages. Should store the latest
    // root generated on the l2 domain.
    func _process_message{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_data_arr_len: felt, _data_arr: Uint256*) {
        // TODO: complete
        // TODO: if not used, this function should revert/not be exposed (check connext's contract)
        return ();
    }

    //TODO: Implement logic. In connext impl, these are virtual. As we will have only one contract
    //      These functions can be implemented here
    // @notice Verify that the msg.sender is the correct AMB contract, and that the message's origin sender
    // is the expected address.
    // @dev Should be overridden by the implementing Connector contract.
    func _verify_sender{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_expected: felt) -> (bool: felt) {
        // TODO: complete
        // TODO: remove placeholder. this function returns a boolean
        return (bool=1);
    }

    // ============ Getters ============

    // @notice The domain of this Messaging (i.e. Connector) contract.
    func domain{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (domain: felt) {
        return Connector_domain.read();
    }

    // @notice Address of the AMB on this domain.
    func amb{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (amb: felt) {
        return Connector_amb.read();
    }

    // @notice RootManager contract address.
    func root_manager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (root_manager: felt) {
        return Connector_root_manager.read();
    }

    // @notice The domain of the corresponding messaging (i.e. Connector) contract.
    func mirror_domain{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (mirror_domain: felt) {
        return Connector_mirror_domain.read();
    }

    // @notice Connector on L2 for L1 connectors, and vice versa.
    func mirror_connector{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (mirror_connector: felt) {
        return Connector_mirror_connector.read();
    }
  }
     
     // ============ Private Functions ============

    func _set_mirror_connector{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_mirror_connector: felt) {
        let (mirror_connector) = Connector_mirror_connector.read();
        MirrorConnectorUpdated.emit(mirror_connector, _mirror_connector);
        Connector_mirror_connector.write(_mirror_connector);
        return ();
    }
    

  