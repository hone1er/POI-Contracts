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

        // Deploy the ProofOfInteraction contract
        proofOfInteraction = new ProofOfInteraction(
            address(this), // Initial owner
            10e18, // Reward rate
            1e18, // Ice breaker fee
            1 seconds, // Minimum reward interval
            address(blueToken), // Address of the mock ERC20 token
            treasury // treasury address
        );

        // Allocate some tokens to the user and the treasury
        blueToken.mint(user, 1000e18);
        blueToken.mint(treasury, 2000000000e18);

        // Approve the ProofOfInteraction contract to spend tokens on behalf of the user
        vm.prank(user);
        blueToken.approve(address(proofOfInteraction), 2000000000e18);
        vm.stopPrank();

        // Approve the ProofOfInteraction contract to spend tokens on behalf of the treasury
        vm.prank(treasury);
        blueToken.approve(address(proofOfInteraction), 2000000000e18);
        vm.stopPrank();
    }

    function testTipUser() public {
        // Simulate the user tipping the invitee
        vm.prank(user);
        proofOfInteraction.tipUser(invitee, 10e18);

        // Check the invitee's balance
        uint256 inviteeBalance = blueToken.balanceOf(invitee);
        assertEq(
            inviteeBalance,
            10e18,
            "Invitee should have received 10 tokens"
        );

        // Check the user's balance
        uint256 userBalance = blueToken.balanceOf(user);
        assertEq(userBalance, 990e18, "User should have 990 tokens left");

        console.log("User's balance:", userBalance);
        console.log("Invitee's balance:", inviteeBalance);
    }

    function testSendIceBreaker() public {
        // Simulate the user sending an ice breaker to the invitee
        vm.prank(user);
        uint256 treasuryInitialBalance = blueToken.balanceOf(treasury);

        proofOfInteraction.sendIceBreaker(invitee);

        // Check the treasury's balance
        uint256 treasuryBalance = blueToken.balanceOf(treasury);
        assertEq(
            treasuryBalance,
            treasuryInitialBalance + 1e18,
            "Treasury should have received 1 token"
        );

        // Check the user's balance
        uint256 userBalance = blueToken.balanceOf(user);
        assertEq(userBalance, 999e18, "User should have 999 tokens left");

        console.log("User's balance:", userBalance);
        console.log("Treasury's balance:", treasuryBalance);
    }

    function testRewardUsers() public {
        // Simulate the owner calling the rewardUsers function
        vm.prank(address(this));
        uint256 rewardValue = proofOfInteraction.calculateRewards(
            user,
            invitee
        );
        uint256 initialUserBalance = blueToken.balanceOf(user);

        proofOfInteraction.rewardUsers(user, invitee);

        console.log("testRewardUsers ~ rewardValue:", rewardValue);

        // Check the invitee's balance
        uint256 inviteeBalance = blueToken.balanceOf(invitee);
        console.log(" ~ testRewardUsers ~ inviteeBalance:", inviteeBalance);
        assertEq(
            inviteeBalance,
            rewardValue,
            "Invitee received wrong amount of tokens"
        );

        // Check the user's balance
        uint256 userBalance = blueToken.balanceOf(user);
        assertEq(
            userBalance,
            initialUserBalance + rewardValue,
            "User should have received 10 tokens"
        );

        console.log("User's balance:", userBalance);
        console.log("Invitee's balance:", inviteeBalance);

        // Check total rewards and last reward time
        uint256 userTotalRewards = proofOfInteraction.getUserRewards(user);
        uint256 inviteeTotalRewards = proofOfInteraction.getUserRewards(
            invitee
        );
        assertEq(
            userTotalRewards,
            rewardValue,
            "User's total rewards should be 0.5 tokens"
        );
        assertEq(
            inviteeTotalRewards,
            rewardValue,
            "Invitee's total rewards should be 0.5 tokens"
        );

        uint256 userLastRewardTime = proofOfInteraction.getUserLastRewardTime(
            user
        );
        uint256 inviteeLastRewardTime = proofOfInteraction
            .getUserLastRewardTime(invitee);
        assertEq(
            userLastRewardTime,
            block.timestamp,
            "User's last reward time should be the current block timestamp"
        );
        assertEq(
            inviteeLastRewardTime,
            block.timestamp,
            "Invitee's last reward time should be the current block timestamp"
        );

        console.log("User's total rewards:", userTotalRewards);
        console.log("Invitee's total rewards:", inviteeTotalRewards);
    }
}
