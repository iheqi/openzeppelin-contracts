// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */

// BeaconProxy: 代理合约
// UpgradeableBeacon: 信标合约

// 透明代理和UUPS代理，都存在一种缺陷，就是如果我要升级一批具有相同逻辑合约的代理合约，那么需要在每个代理合约都执行一遍升级
// 而信标代理合约，可以在一次交易中使多个代理合约进行升级
// 在这种模式中，代理合约不像 ERC1967 代理那样在存储中保存 implementation地址。(解耦)
// 信标合约将所有的具有相同逻辑合约的代理合约的_implementation 只存一份在信标合约中，
// 所有的代理合约通过和信标合约接口调用，获取_implementation
// (但是他妈的什么场景会一个逻辑合约有多个代理合约？这玩意感觉扯淡，你写个mutilcall不好吗)
// https://learnblockchain.cn/article/4936

contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    // 从信标合约获取implementation，因此只有修改信标合约或者信标合约修改implementation即可升级
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    // 设置信标合约 
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}
