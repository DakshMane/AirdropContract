// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MerkleAirDrop} from "../src/MerkleAirdrop.sol";
import {GrunoToken} from "../src/GrunoToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
contract DeployMerkleAirdrop is ZkSyncChainChecker, Script {
    bytes32 private s_merkleRoot =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private s_amountToTransfer = 4 * 25 * 1e18;

    function deployMerkleAirdrop() public returns (MerkleAirDrop, GrunoToken) {
        vm.startBroadcast();
        GrunoToken token = new GrunoToken();
        MerkleAirDrop airdrop = new MerkleAirDrop(
            s_merkleRoot,
            IERC20(address(token))
        );
        token.mint(token.owner(), s_amountToTransfer);
        token.transfer(address(airdrop), s_amountToTransfer);
        vm.stopBroadcast();
        return (airdrop, token);
    }

    function run() external returns (MerkleAirDrop, GrunoToken) {
        return deployMerkleAirdrop();
    }
}
