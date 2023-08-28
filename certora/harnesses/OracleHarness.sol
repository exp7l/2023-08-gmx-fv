// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Oracle, DataStore, EventEmitter, RoleStore, OracleStore} from "../../contracts/oracle/Oracle.sol";
import {OracleUtils} from "../../contracts/oracle/OracleUtils.sol";
import {Bits} from "../../contracts/utils/Bits.sol";
import {Role} from "../../contracts/role/RoleStore.sol";

contract OracleHarness is Oracle {

    DataStore public immutable myDataStore;
    EventEmitter public immutable myEventEmitter;
    OracleUtils.ReportInfo public myReportInfo;
    /// @dev : struct fields of SetPricesParams. See _prepareParams().
    uint256 public mySignerInfo;
    address[] public myTokens;
    uint256[] public myCompactedMinOracleBlockNumbers;
    uint256[] public myCompactedMaxOracleBlockNumbers;
    uint256[] public myCompactedOracleTimestamps;
    uint256[] public myCompactedDecimals;
    uint256[] public myCompactedMinPrices;
    uint256[] public myCompactedMinPricesIndexes;
    uint256[] public myCompactedMaxPrices;
    uint256[] public myCompactedMaxPricesIndexes;
    bytes[] public mySignatures;
    address[] public myPriceFeedTokens;

    constructor(
        RoleStore _roleStore,
        OracleStore _oracleStore,
        DataStore _dataStore,
        EventEmitter _eventEmitter
    ) Oracle(_roleStore, _oracleStore) {
        myDataStore = _dataStore;
        myEventEmitter = _eventEmitter;
    }

    function _prepareParams(uint256 minPrice) internal view returns (OracleUtils.SetPricesParams memory params) {
        require(mySignerInfo & Bits.BITMASK_16 > 0);
        //require(myTokens.length > 0);
	uint256[] memory compactedMinPrices = new uint256[](1);
	compactedMinPrices[0] = minPrice;
	
        params = 
        OracleUtils.SetPricesParams(
            mySignerInfo,
            myTokens,
            myCompactedMinOracleBlockNumbers,
            myCompactedMaxOracleBlockNumbers,
            myCompactedOracleTimestamps,
            myCompactedDecimals,
	    compactedMinPrices,
            myCompactedMinPricesIndexes,
            myCompactedMaxPrices,
            myCompactedMaxPricesIndexes,
            mySignatures,
            myPriceFeedTokens
        );
    }

// https://prover.certora.com/output/61075/610d9ad69e95439797b32ec7134c712a?anonymousKey=8092d1ad2a98f9bb6b04d8839f0758d741b2f6c6

    function setPrices(
        DataStore,
        EventEmitter,
	uint256 minPrice
    ) public {
        super.setPrices(myDataStore, myEventEmitter, _prepareParams(minPrice));
    }

    function getStablePrice(DataStore, address token) public view override returns (uint256) {
        return super.getStablePrice(myDataStore, token);
    }

    function getPriceFeedMultiplier(DataStore, address token) public view override returns (uint256) {
        return super.getPriceFeedMultiplier(myDataStore, token);
    }

    function getSignerByInfo(uint256 signerInfo, uint256 i) public view returns (address) {
        uint256 signerIndex = signerInfo >> (16 + 16 * i) & Bits.BITMASK_16;
        require (signerIndex < MAX_SIGNER_INDEX);
        return oracleStore.getSigner(signerIndex);
    }

    function validateSignerHarness(
        bytes32 SALT,
        bytes memory signature,
        address expectedSigner
    ) external view {
        OracleUtils.validateSigner(SALT, myReportInfo, signature, expectedSigner);
    }

    function someController() external view returns (address) {
        return roleStore.getRoleMembers(Role.CONTROLLER, 0, 1)[0];
    }

    function tokensCount() public returns (uint256) {
    	return myTokens.length;
    }

    function signaturesCount() public returns (uint256) {
    	return mySignatures.length;
    }

    function firstToken() public returns (address) {
    	return myTokens[0];
    }

    function myCompactedMinPricesFn() public returns (uint256[] memory) {
        return myCompactedMinPrices;
    }

    function firstUncompactedMinPrice() public returns (uint256) {
    	return getUncompactedPrice(myCompactedMinPrices, 0);
    }

    function getUncompactedPrice(uint256[] memory compactedPrices, uint256 index) public returns (uint256) {
    	return OracleUtils.getUncompactedPrice(compactedPrices, index);
    }
}







