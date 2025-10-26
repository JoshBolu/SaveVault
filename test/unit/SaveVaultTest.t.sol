// SPDX-License-Identifier:MIT SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {SaveVault} from "../../src/SaveVault.sol";
import {DeploySaveVault} from "../../script/DeploySaveVault.s.sol";

contract SaveVaultTest is Test {
    SaveVault public saveVault;
    address public USER = makeAddr("player");
    uint256 public constant INITIAL_DEPOSIT = 1 ether;
    uint256 public constant LOCK_PERIOD = 3 days;
    uint256 public constant DEPOSIT = 0.5 ether;

    /***** EVENTS *****/
    event vaultCreated(
        address indexed user,
        uint256 startTime,
        uint256 endTime,
        uint256 vaultBalance
    );
    event fundsSaved(address indexed user, uint256 amountSaved);

    function setUp() public {
        DeploySaveVault deployer = new DeploySaveVault();
        saveVault = deployer.deployContract();
        vm.deal(USER, INITIAL_DEPOSIT);
    }

    function testCreateVault() public {
        // Arrange
        vm.prank(USER);

        // Act
        saveVault.createVault(LOCK_PERIOD);

        // Assert
        uint256 balance = saveVault.viewBalance();
        assertEq(balance, 0);
    }

    function testAlreadyExistingVaultCantCreateAnother() public {
        // Arrange
        vm.prank(USER);
        saveVault.createVault(LOCK_PERIOD);
        vm.prank(USER);
        saveVault.saveFunds{value: DEPOSIT}();

        // Act
        vm.expectRevert(SaveVault.SaveVault__VaultAlreadyExists.selector);
        vm.prank(USER);
        saveVault.createVault(LOCK_PERIOD);
    }

    function testCantSaveFundsWithoutCreatingVault() public {
        // Act
        vm.prank(USER);
        vm.expectRevert(SaveVault.SaveVault__VaultDoesNotExist.selector);
        saveVault.saveFunds{value: DEPOSIT}();
    }

    function testSaveFunds() public {
        // Arrange
        vm.prank(USER);
        saveVault.createVault(LOCK_PERIOD);
        vm.prank(USER);
        saveVault.saveFunds{value: DEPOSIT}();

        // Act & Assert
        vm.prank(USER);
        assertEq(saveVault.viewBalance(), DEPOSIT);
    }

    function testCreateVaultEmitsEvent() public {
        // Arrange
        vm.prank(USER);

        // Assert
        vm.expectEmit(true, true, true, true, address(saveVault));
        emit vaultCreated(
            USER,
            block.timestamp,
            block.timestamp + LOCK_PERIOD,
            0
        );

        // Act
        saveVault.createVault(LOCK_PERIOD);
    }

    function testTimeSavedProperly() public {
        // Arrange
        vm.prank(USER);

        // Act
        saveVault.createVault(LOCK_PERIOD);
        vm.prank(USER);
        uint256[2] memory duration = saveVault.viewSaveDuration();

        // Assert
        assertEq(duration[0], block.timestamp);
        assertEq(duration[1], block.timestamp + LOCK_PERIOD);
    }

    function testWihdrawOfAddressWithoutVaultExisting() public {
        // Arrange
        vm.prank(USER);

        // Act
        vm.expectRevert(SaveVault.SaveVault__VaultDoesNotExist.selector);
        saveVault.withdrawFunds();
    }

    function testWihdrawfundsBeforeLockDurationOver() public {
        // Arrange
        vm.prank(USER);
        saveVault.createVault(LOCK_PERIOD);
        vm.prank(USER);
        saveVault.saveFunds{value: DEPOSIT}();
        vm.prank(USER);

        // Act & Assert
        vm.expectRevert(SaveVault.SaveVault__LockPeriodNotOver.selector);
        saveVault.withdrawFunds();
    }

    function testWihdrawAfterTimeHasPassed() public {
        // Arrange
        vm.prank(USER);
        saveVault.createVault(LOCK_PERIOD);
        vm.prank(USER);
        saveVault.saveFunds{value: DEPOSIT}();

        // Act
        vm.warp(block.timestamp + LOCK_PERIOD + 1);
        vm.roll(block.number + 40);
        vm.prank(USER);
        saveVault.withdrawFunds();

        // Assert
        vm.prank(USER);
        vm.assertEq(saveVault.viewBalance(), 0);
    }
}

// Discovered something new when you use mapping for an address to uint balance if you use a conditional statement that requires it to be 0 to do something that condition will always be true even without the person creating an address map in your code
