// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */

    // https://eips.ethereum.org/EIPS/eip-1271
    // EOA 有私钥进行签署消息，但合约没有私钥。为此给合约制定一种标准来验证代表给定合约的签名是否有效。(代表是该是合约签署的签名)
    // 这可以通过在签名合约上实现一个isValidSignature(hash, signature)函数来实现，可以调用该函数来验证签名。

    // 验证 signature 对于给定的 signer 和 数据hash 是否有效。如果签名者是智能合约，则使用 E​​RC1271 针对该智能合约验证签名，否则使用ECDSA.recover 

    // 在 https://eips.ethereum.org/EIPS/eip-1271 中有签名合约的 isValidSignature 实现
    // (妈的，最终还是用EOA进行签名和验证啊，将签名合约和一个EOA绑定在一起)
    // 举个应用场景：链下订单簿的去中心化交易
    // 之前的方式是EOA 签署订单，发送给 交易所智能合约 通过签名完成交易 （EOA ==签名、发送==> 交易所智能合约）
    // 如果有中间商想做一个 中间商合约服务，链路变为：EOA ==发送数据(不签名)==> 中间商合约 ==签名===> 交易所智能合约
    // 显然中间商合约现在是无法签名的，所以引入这个规范，相当于让合约也可以签名

    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        // 1.先进行常规验证
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        // 2.如果上面不通过，则将 signer 作为一个合约地址，调用其 isValidSignature 函数进行验证
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}
