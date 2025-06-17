//SPDX-License-Identifier : MIT

pragma solidity ^0.8.20;
import {Test, console} from "forge-std/Test.sol";
import {MerkleAirDrop} from "../src/MerkleAirdrop.sol";
import {GrunoToken} from "../src/GrunoToken.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirDrop.s.sol";
contract MerkleAirDropTest is Test, ZkSyncChainChecker {
    MerkleAirDrop public airdrop;

    GrunoToken public token;
    address user;
    address gasPayer;
    uint256 userPrivKey;
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public AMOUNT_TO_MINT = AMOUNT_TO_CLAIM * 4;
    bytes32 proofOne =
        0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 prooftwo =
        0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, prooftwo];

    bytes32 public ROOT =
        0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            token = new GrunoToken();
            airdrop = new MerkleAirDrop(ROOT, token);
            token.mint(token.owner(), AMOUNT_TO_MINT);
            token.transfer(address(airdrop), AMOUNT_TO_MINT);
        }

        (user, userPrivKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function testUserCanClaim() public {
        // checking if ending balance - starting = AMOUNT_TO_CLAIM
        uint256 startingBalance = token.balanceOf(user);
        //signing needs digest of message hash and private key
        bytes32 digest = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, digest);

        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);
        uint256 endingBalance = token.balanceOf(user);
        assertEq(
            endingBalance - startingBalance,
            AMOUNT_TO_CLAIM,
            "User should have received the claimed amount"
        );
    }
}
