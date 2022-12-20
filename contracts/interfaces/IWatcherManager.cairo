%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IWatcherManager {
    func isWatcher(_watcher: felt) -> (is_watcher: felt) {
    }

    func addWatcher(_watcher: felt) -> () {
    }

    func removeWatcher(_watcher: felt) -> () {
    }

    func renounceOwnership(_watcher: felt) -> (is_watcher: felt) {
    }
}