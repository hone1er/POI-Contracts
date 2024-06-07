// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ProofOfInteraction
 * @author Hone1er
 * @notice A contract that rewards users for Proof of Interaction
 */
contract ProofOfInteraction is Ownable, ReentrancyGuard {
    /*                    */
    /*  TYPE DEFINITIONS  */
    /*                    */
    struct User {
        uint256 totalRewards;
        uint256 lastRewardTime;
    }

    /*                   */
    /*  STATE VARIABLES  */
    /*                   */
    IERC20 immutable i_blueToken;

    uint256 public rewardRate;
    uint256 public iceBreakerFee;
    uint256 public minimumRewardInterval;

    mapping(address => User) public userRewards;
    mapping(uint256 hashedAddresses => uint256 interactionCount)
        public userInteractions;

    /*        */
    /* EVENTS */
    /*        */
    event TipSent(address indexed user, uint256 amount);
    event RewardUser(address indexed user, uint256 reward);
    event BalanceWithdrawn(address indexed owner, uint256 amount);
    event IceBreakerSent(address indexed user, address indexed invitee);

    /*          */
    /*  ERRORS  */
    /*          */
    error RewardTransferFailedError();
    error RewardIntervalError();
    error IceBreakerFeeError();
    error TipUserError();

    /*             */
    /*  MODIFIERS  */
    /*             */
    modifier onlyAfterRewardInterval(address user) {
        if (
            block.timestamp - userRewards[user].lastRewardTime <
            minimumRewardInterval
        ) {
            revert RewardIntervalError();
        }
        _;
    }

    /*             */
    /*  FUNCTIONS  */
    /*             */
    constructor(
        address initialOwner,
        uint256 _rewardRate,
        uint256 _iceBreakerFee,
        uint256 _minimumRewardInterval,
        address _blueToken
    ) Ownable(initialOwner) {
        iceBreakerFee = _iceBreakerFee;
        rewardRate = _rewardRate;
        minimumRewardInterval = _minimumRewardInterval;
        i_blueToken = IERC20(_blueToken);
    }

    /**
     *
     * @param _invitee address of the user to send the ice breaker to
     * @dev Sends an ice breaker fee to the treasury and emits an event
     */
    function sendIceBreaker(address _invitee) external nonReentrant {
        bool success = i_blueToken.transferFrom(
            msg.sender,
            address(this),
            iceBreakerFee
        );
        if (!success) {
            revert IceBreakerFeeError();
        }
        emit IceBreakerSent(msg.sender, _invitee);
    }

    /**
     * @param  _userA address of the first user to reward
     * @param  _userB address of the second user to reward
     * @dev Rewards multiple users with the reward rate
     *
     */
    function rewardUsers(
        address _userA,
        address _userB
    ) external onlyOwner nonReentrant {
        uint256 rewardValue = calculateRewards(_userA, _userB);
        rewardUser(_userA, rewardValue);
        rewardUser(_userB, rewardValue);
        incrementInteractionCount(_userA, _userB);
    }

    /**
     *
     * @param _user address of the user to reward
     * @dev Rewards a user with the reward rate
     *
     * @notice This function is only callable by the owner and after the reward interval has passed since the last reward
     */
    function rewardUser(
        address _user,
        uint256 _rewardValue
    ) internal onlyAfterRewardInterval(_user) {
        bool success = i_blueToken.transferFrom(
            address(this),
            _user,
            _rewardValue
        );
        if (!success) {
            revert RewardTransferFailedError();
        }
        emit RewardUser(_user, _rewardValue);
    }

    /**
     *
     * @param _user address of the user to tip
     * @param _amount amount to tip the user in BLUE tokens
     * @dev Tips a user with the specified amount of BLUE tokens
     */
    function tipUser(address _user, uint256 _amount) external nonReentrant {
        bool success = i_blueToken.transferFrom(msg.sender, _user, _amount);
        if (!success) {
            revert TipUserError();
        }
        emit TipSent(_user, _amount);
    }

    function incrementInteractionCount(address _userA, address _userB) public {
        // sort the addresses to avoid duplicate counts
        // Ensure the addresses are sorted to avoid duplicates
        (address addr1, address addr2) = _userA < _userB
            ? (_userA, _userB)
            : (_userB, _userA);
        uint256 hashedAddresses = uint256(
            keccak256(abi.encodePacked(addr1, addr2))
        );
        userInteractions[hashedAddresses]++;
    }

    function calculateRewards(
        address _userA,
        address _userB
    ) public view returns (uint256) {
        (address addr1, address addr2) = _userA < _userB
            ? (_userA, _userB)
            : (_userB, _userA);
        uint256 hashedAddresses = uint256(
            keccak256(abi.encodePacked(addr1, addr2))
        );
        uint256 interactionCount = userInteractions[hashedAddresses];
        return rewardRate / (1 + interactionCount);
    }

    /**
     *
     * @param _user address of the user to get rewards for
     * @return total rewards for the user
     */
    function getUserRewards(address _user) public view returns (uint256) {
        return userRewards[_user].totalRewards;
    }

    /**
     *
     * @param _user address of the user to get the last reward time for
     * @return last reward time for the user
     */
    function getUserLastRewardTime(
        address _user
    ) public view returns (uint256) {
        return userRewards[_user].lastRewardTime;
    }

    /**
     *
     * @param _iceBreakerFee new ice breaker fee
     * @dev Sets the ice breaker fee
     */
    function setIceBreakerFee(uint256 _iceBreakerFee) public onlyOwner {
        iceBreakerFee = _iceBreakerFee;
    }

    /**
     *
     * @param _rewardRate new reward rate
     * @dev Sets the reward rate
     */
    function setRewardRate(uint256 _rewardRate) public onlyOwner {
        rewardRate = _rewardRate;
    }

    /**
     *
     * @param _minimumRewardInterval new minimum reward interval
     * @dev Sets the minimum reward interval
     */
    function setMinimumRewardInterval(
        uint256 _minimumRewardInterval
    ) public onlyOwner {
        minimumRewardInterval = _minimumRewardInterval;
    }

    /**
     * @dev Withdraws the contract balance to the owner
     */
    function withdraw() public nonReentrant onlyOwner {
        payable(owner()).transfer(address(this).balance);
        emit BalanceWithdrawn(owner(), address(this).balance);
    }
}
