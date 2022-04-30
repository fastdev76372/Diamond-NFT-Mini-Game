// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// LibDiamond 💎 Allows For Diamond Storage
import "../libraries/LibDiamond.sol";

// LibStakeNFTStorage 💎 Allows For Diamond Storage
import "../libraries/LibStakeStorage.sol";

// Structs imported from DiamondStorage
import {LibERC721} from "../libraries/LibERC721.sol";

import "../libraries/LibAppStorage.sol";

// Structs imported from AppStorage
import {CharacterAttributes, BigBoss} from "../libraries/LibAppStorage.sol";

// Hardhat Console Debugging Easy
// import "hardhat/console.sol";

import "./DynamicGameFacet.sol";



// @title NFT Based Mini Game
/// @author Shiva Shanmuganathan
/// @notice You can use this contract for implementing a simple NFT based game to change NFT Metadata
/// @dev All function calls are currently implemented without side effects
contract StakeNFTFacet {
    AppStorage internal s;

    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;


    // Events to show that a Minting & Attacking action has been completed 
    event AssetStaked(uint tokenId, uint stakeStartTime);
    event AssetUnstaked(uint tokenId, uint newPlayerHp, uint stakeStartTime, uint stakeEndTime);

    // Data is passed in to the contract when it's first created initializing the characters.
    // We're going to actually pass these values in from from run.js.
  
    /// @notice User with NFT can stake their character [Metadata Of NFT Changes Here]
    /// @dev The Health of User's NFT is increased becuase of staking. [Metadata Of NFT Changes Here]
    /// The user's address & index is used to get the NFT the user owns
    /// Health of Hero is increased due to staking  
    function stakeCharacter(uint tokenID, address contractAddress) external {
        
        LibStakeStorage.StakeStorage storage lss = LibStakeStorage.diamondStorage();
        // Get the state of the player's NFT.
        // uint256 nftTokenIdOfPlayer = s.nftHolders[msg.sender][_index];
        require(s._owners[tokenID] == msg.sender, "Not NFT Owner");        
        LibStakeStorage.StakeInfo storage staked_asset = lss.stakingInfo[contractAddress][tokenID];

        require(staked_asset.startTime == 0, "NFT Already Staked.");
        CharacterAttributes memory player = s.nftHolderAttributes[tokenID];
        require(player.hp < player.maxHp, "Player Already Has Enough Hp");

        staked_asset.startTime = block.timestamp;
        staked_asset.staker = msg.sender;
        

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        bytes4 functionSelector = bytes4(keccak256("transferFrom(address,address,uint256)"));
        // get facet address of function 
        address facet = ds.facetAddressAndSelectorPosition[functionSelector].facetAddress; 

        console.log("Address of THIS CONTRACT", address(this));

        // (bool success, ) = facet.delegatecall(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), tokenID));
        // require(success, "transfer failed"); 
        LibERC721._safeTransfer(msg.sender, address(this), tokenID, "");

        emit AssetStaked(tokenID, staked_asset.startTime);

    }

    /// @notice User with NFT can stake their character [Metadata Of NFT Changes Here]
    /// @dev The Health of User's NFT is increased becuase of staking. [Metadata Of NFT Changes Here]
    /// The user's address & index is used to get the NFT the user owns
    /// Health of Hero is increased due to staking  
    function unStakeCharacter(uint tokenID, address contractAddress) external {
        LibStakeStorage.StakeStorage storage lss = LibStakeStorage.diamondStorage();
        // Get the state of the player's NFT.
        // uint256 nftTokenIdOfPlayer = s.nftHolders[msg.sender][_index];
        
        LibStakeStorage.StakeInfo storage staked_asset = lss.stakingInfo[contractAddress][tokenID];
        require(staked_asset.startTime != 0, "NFT Is Not Staked.");
        require(staked_asset.staker == msg.sender, "Not NFT Staker");

        CharacterAttributes storage player = s.nftHolderAttributes[tokenID];

        uint stakedTime = block.timestamp - staked_asset.startTime;
        
        player.hp = player.hp + (stakedTime/60);

        if(player.hp >= player.maxHp){
            player.hp = player.maxHp;
        }

        staked_asset.startTime = 0;
        
        DynamicGameFacet(address(this)).transferFrom(address(this), msg.sender, tokenID);
        // LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // bytes4 functionSelector = bytes4(keccak256("transferFrom(address,address,uint256)"));
        
        // address facet = ds.facetAddressAndSelectorPosition[functionSelector].facetAddress; 

        // console.log("Address of THIS CONTRACT", address(this));
        // console.log("USER Address ", msg.sender);


        // (bool approval_success, bytes memory approval_data) = facet.delegatecall(abi.encodeWithSignature("approve(address,uint256)", msg.sender, tokenID));
        // require(approval_success, "approval failed"); 

        // (bool success, bytes memory data) = facet.delegatecall(abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), msg.sender, tokenID));
        
        // require(success, "transfer failed"); 

        emit AssetUnstaked(tokenID, player.hp, staked_asset.startTime, block.timestamp);

    }


    function getStartTime(uint tokenID, address contractAddress) external view returns(uint256){
        
        LibStakeStorage.StakeStorage storage lss = LibStakeStorage.diamondStorage();        
        LibStakeStorage.StakeInfo memory staked_asset = lss.stakingInfo[contractAddress][tokenID];
        return staked_asset.startTime;
        
    }


    // function onERC721Received(address _from, uint256 _tokenId, bytes calldata _data) public returns(bytes4) {
    //     return ERC721_RECEIVED;
    // }

    function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external view returns (bytes4) {
		if (msg.sender != address(this)) {
			revert("Error.InvalidToken");
		}
		return
			bytes4(
				keccak256('onERC721Received(address,address,uint256,bytes)')
			);
	}


  

}
