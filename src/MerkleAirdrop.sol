//SPDX-License-Identifier : MIT

pragma solidity ^0.8.20;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
contract MerkleAirDrop is EIP712 {
    using SafeERC20 for IERC20;
    error MerkleAirdrop__InvalidProof();
    error MerkleAirDrop__AlreadyClaimed();
    error MerkleAirDrop__InvalidSignature();
    event Claim(address account, uint256 amount);
    address[] claimers;
    bytes32 private immutable i_merkleRoot;

    bytes32 private constant MESSAGE_TYPEHASH =
        keccak256("AirDropClaim(address account,uint256 amount)");
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    constructor(
        bytes32 merkleRoot,
        IERC20 airdropToken
    ) EIP712("MerkleAirDrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    struct AirDropClaim {
        address account;
        uint256 amount;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (s_hasClaimed[account]) revert MerkleAirDrop__AlreadyClaimed();

        if (
            !_isValidSignature(
                account,
                getMessageHash(account, amount),
                v,
                r,
                s
            )
        ) revert MerkleAirDrop__InvalidSignature();
        // hashing it twice  to avoid second pre-image attack
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount)))
        );
        //checks
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf))
            revert MerkleAirdrop__InvalidProof();
        //effect
        s_hasClaimed[account] = true;
        emit Claim(account, amount);

        //interactions
        i_airdropToken.safeTransfer(account, amount);
    }

    function getMessageHash(
        address account,
        uint256 amount
    ) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(MESSAGE_TYPEHASH, AirDropClaim(account, amount))
                )
            );
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirDropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    function _isValidSignature(
        address account,
        bytes32 message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bool) {
        (address actualSigner, , ) = ECDSA.tryRecover(message, v, r, s);
        return actualSigner == account;
    }
}
