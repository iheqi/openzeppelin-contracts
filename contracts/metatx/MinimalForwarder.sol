// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSA.sol";
import "../utils/cryptography/EIP712.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 *
 * MinimalForwarder is mainly meant for testing, as it is missing features to be a good production-ready forwarder. This
 * contract does not intend to have all the properties that are needed for a sound forwarding system. A fully
 * functioning forwarding system with good properties requires more complexity. We suggest you look at other projects
 * such as the GSN which do have the goal of building a system like that.
 */

// https://www.jb51.net/blockchain/802363.html
// https://blog.csdn.net/shengzang1998/article/details/121263348
// 元交易（Metatransaction），是一种让用户不需要支付 gas 费就能够使用 DApp、发起交易、调用智能合约的手段。
// 需要使用元交易智能合约实现
contract MinimalForwarder is EIP712 {
    using ECDSA for bytes32;

    // ForwardRequest 结构体定义了一个交易中用于签名的基本组成成分
    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce; // 为了避免双花攻击，在智能合约中维护 nonce 是必要的
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    // 执行元交易
    // 调用示例：
    // 如果 Alice 没有足够的 ETH 支付 gas 费，来铸造一个 NFT，她可以签署一个元交易，元交易的 data 是由 abi.encodeWithSignature(functionSelector, parmas...) 得到的，
    // 将该元交易递交给具有足够 ETH 的 Bob，Bob 调用元交易合约 MinimalForwarder.execute(req, signature)，从而让 Alice 的元交易成功执行。
    // (整体流程就是别人帮你发起交易教一下手续费，然后msg.sender还是设置为你)
    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;


        // req.to 为 ERC2771Context.sol 地址
        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.limo/blog/ethereum-gas-dangers/

        // 为避免中间人（代为执行元交易的人）恶意地或无意地使用足够低的 gas 使得交易执行成功，而元交易执行失败
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }
}
