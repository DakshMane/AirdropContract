//SPDX-License-Identifier : MIT

pragma solidity ^0.8.20;

import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

import {Script} from "forge-std/Script.sol";
import {MerkleAirDrop} from "../src/MerkleAirdrop.sol";

contract ClaimAirDrop is Script {
    error __ClaimAirdropScript__InvalidSignatureLength();

    bytes private SIGNATURE =
        hex"49a7c69de4b42137243bd670014412bac9ca8f0a4649586866eb4eb5e975960642f7a1a464e95e9c540a619bf38065603e54f6513c95875478f51e6b1138dff51c";

    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18;
    bytes32 private constant PROOF_ONE =
        0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 private constant PROOF_TWO =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] private PROOF = [PROOF_ONE, PROOF_TWO];
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "MerkleAirDrop",
            block.chainid
        );
        claimAirdrop(mostRecentlyDeployed);
    }

    function splitSignature(
        bytes memory sig
    ) public returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65)
            revert __ClaimAirdropScript__InvalidSignatureLength();
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirDrop(airdrop).claim(
            CLAIMING_ADDRESS,
            AMOUNT_TO_CLAIM,
            PROOF,
            v,
            r,
            s
        );
        vm.stopBroadcast();
    }
}
