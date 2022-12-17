// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */

// 要支持元交易，仅实现元交易智能合约(MinimalForwarder)是不够的，因为目标合约无法知道实际的元交易 from 是谁。
// 如果没有额外的措施，它将只能够从 msg.sender 中获取，由于在元交易合约实现中，是通过 Address.call 调用的，
// 因此将得到的发送者是元交易合约 MinimalForwarder 的地址。
// ERC2771 元交易的安全协议则解决了该问题，获取 MinimalForwarder 传递过来的 req.from 作为 msg.sender

abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }


    // 元交易的调用方forwarder是否是设置的元交易合约地址_trustedForwarder
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    // 重写了 Context.sol 的 _msgSender
    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            // assembly 代码元交易合约中 req.to.call{...}(abi.encodePacked(req.data, req.from)) 编码进的 data 部分内容的 req.from 获取到
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}
