// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ProofOfInteraction} from "../src/ProofOfInteraction.sol";
import {BlueToken} from "test/mocks/BlueToken.sol";

contract ProofOfInteractionTest is Test {
    ProofOfInteraction public proofOfInteraction;
    BlueToken public blueToken;
    address public user = address(1);
    address public invitee = address(2);
    address public treasury = address(3);

    function setUp() public {
        // Deploy the mock ERC20 token
        blueToken = new BlueToken("Blue Token", "BLUE", 18);

        // mock treasury address

        // Deploy the ProofOfInteraction contract
        proofOfInteraction = new ProofOfInteraction(
            address(this), // Initial owner
            10e18, // Reward rate
            1e18, // Ice breaker fee
            1 days, // Minimum reward interval
            address(blueToken) // Address of the mock ERC20 token
        );

        // Allocate some tokens to the user
        blueToken.mint(user, 1000 * 10 ** 18);
        blueToken.mint(treasury, 2000000000 * 10 ** 18);

        // Approve the ProofOfInteraction contract to spend tokens on behalf of the user
        vm.prank(user);
        blueToken.approve(address(proofOfInteraction), 100000000 * 10 ** 18);
        blueToken.approve(user, 100000000 * 10 ** 18);
    }

    function testTipUser() public {
        // Simulate the user tipping the invitee
        vm.prank(user);
        proofOfInteraction.tipUser(invitee, 10 * 10 ** 18);

        // Check the invitee's balance
        uint256 inviteeBalance = blueToken.balanceOf(invitee);
        assertEq(
            inviteeBalance,
            10 * 10 ** 18,
            "Invitee should have received 10 tokens"
        );

        // Check the user's balance
        uint256 userBalance = blueToken.balanceOf(user);
        assertEq(
            userBalance,
            990 * 10 ** 18,
            "User should have 990 tokens left"
        );

        console.log("User's balance:", userBalance);
        console.log("Invitee's balance:", inviteeBalance);
    }

    function testSendIceBreaker() public {
        // Simulate the user sending an ice breaker to the invitee
        vm.prank(user);
        proofOfInteraction.sendIceBreaker(invitee);

        // Check the treasury's balance
        uint256 inviteeBalance = blueToken.balanceOf(
            address(proofOfInteraction)
        );
        assertEq(
            inviteeBalance,
            1 * 10 ** 18,
            "Invitee should have received 1 token"
        );

        // Check the user's balance
        uint256 userBalance = blueToken.balanceOf(user);
        assertEq(
            userBalance,
            999 * 10 ** 18,
            "User should have 999 tokens left"
        );

        console.log("User's balance:", userBalance);
        console.log("Invitee's balance:", inviteeBalance);
    }

    function testRewardUsers() public {
        // Simulate the user tipping the invitee
        vm.prank(user);
        proofOfInteraction.rewardUsers(user, invitee);

        // Check the invitee's balance
        uint256 inviteeBalance = blueToken.balanceOf(invitee);
        assertEq(
            inviteeBalance,
            20 * 10 ** 18,
            "Invitee should have received 20 tokens"
        );

        // Check the user's balance
        uint256 userBalance = blueToken.balanceOf(user);
        assertEq(
            userBalance,
            980 * 10 ** 18,
            "User should have 980 tokens left"
        );

        console.log("User's balance:", userBalance);
        console.log("Invitee's balance:", inviteeBalance);
    }
}
