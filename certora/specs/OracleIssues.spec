methods {
    // DataStore
    function _.getUint(bytes32) external => DISPATCHER(true);
    function _.getAddress(bytes32) external => DISPATCHER(true);
    function _.getBytes32(bytes32) external => DISPATCHER(true);
    // RoleStore
    // function _.hasRole(address,bytes32) external => DISPATCHER(true);
    function _.hasRole(address,bytes32) external => ALWAYS(true);
    // OracleStore
    function _.getSigner(uint256) external => DISPATCHER(true);
    // PriceFeed
    function _.latestRoundData() external => DISPATCHER(true);
    /// Chain
    // function _.arbBlockNumber() external => ghostBlockNumber() expect uint256 ALL;n
    function _.arbBlockHash(uint256 blockNumber) external => ghostBlockHash(blockNumber) expect bytes32 ALL;
    /// Oracle summaries
    function Oracle._getSalt() internal returns bytes32 => mySalt();

    /// Getters:
    function OracleHarness.primaryPrices(address) external returns (uint256,uint256);
    function OracleHarness.secondaryPrices(address) external returns (uint256,uint256);
    function OracleHarness.customPrices(address) external returns (uint256,uint256);
    function OracleHarness.getSignerByInfo(uint256, uint256) external returns (address);


    function _.getRoleMembers(bytes32,uint256,uint256) external => DISPATCHER(true);
    function _.arbBlockNumber() external => ALWAYS(42);

    function signaturesCount() external returns uint256 envfree;
    function tokensCount() external returns uint256 envfree;
    function someController() external returns address envfree;
    function firstToken() external returns address envfree;
    function firstUncompactedMinPrice() external returns uint256 envfree;
}

ghost mySalt() returns bytes32;

ghost ghostBlockNumber() returns uint256 {
    axiom ghostBlockNumber() !=0;
}

ghost ghostBlockHash(uint256) returns bytes32 {
    axiom forall uint256 num1. forall uint256 num2. 
        num1 != num2 => ghostBlockHash(num1) != ghostBlockHash(num2);
}

function e_block_number(env e) returns uint256 {
    return 42;
}

function ghostMedian(uint256[] array) returns uint256 {
    uint256 med;
    uint256 len = array.length;
    require med >= array[0] && med <= array[require_uint256(len-1)];
    return med;
}

rule sanity_satisfy(method f) {
    env e;
    calldataarg args;
    f(e, args);
    satisfy true;
}

rule validateSignerConsistency() {
    env e1; env e2;
    require e1.msg.value == e2.msg.value;
    
    bytes32 salt1;
    bytes32 salt2;
    address signer1;
    address signer2;
    bytes signature;

    validateSignerHarness(e1, salt1, signature, signer1);
    validateSignerHarness@withrevert(e2, salt2, signature, signer2);

    assert (salt1 == salt2 && signer1 == signer2) => !lastReverted,
        "Revert characteristics of validateSigner are not consistent";
}

// COMMAND:
//
// certoraRun certora/confs/oracle_violated.conf --rule getPrimaryPriceComplyPrecision --prover_args '-s z3 -copyLoopUnroll 5 -mediumTimeout 1 -depth 30 -dontStopAtFirstSplitTimeout true'
//
// EXAMPLE:
//
// https://prover.certora.com/output/61075/610d9ad69e95439797b32ec7134c712a/?anonymousKey=8092d1ad2a98f9bb6b04d8839f0758d741b2f6c6
// 
// RULE:
//
// The following verifies that setPrices uncompacts and stores prices correctly.
// 
// From the comments of setPrices:
// '''Oracle prices are signed as a value together with a precision, this allows
// prices to be compacted as uint32 values.
// The signed prices represent the price of one unit of the token using a value
// with 30 decimals of precision.'''
// 
// As per comment of setPrices, setPrices should uncompact the signed uint32s in the parameters and scale by 10 ^ 30. and a predefinied precision. But, the code doesn't do these because the code doesn't enforce precision and trust the inputs. [2]
// The trusted oracles can inadvertently or maliciously provide price updates that are
// of the wrong precision if there is no external price feed [1].
// 
// [1]: https://github.com/exp7l/2023-08-gmx-fv/blob/40a44b01f8c69c9a58c17df0dd85c6455d9a8038/contracts/oracle/Oracle.sol#L530
// [2]: https://github.com/exp7l/2023-08-gmx-fv/blob/40a44b01f8c69c9a58c17df0dd85c6455d9a8038/contracts/oracle/Oracle.sol#L526
rule getPrimaryPriceComplyPrecision {
    // Variables
    env e;
    address dataStore;
    address eventEmitter;
    uint256 minPrice;

    // Caller is a Controller
    require e.msg.sender == someController();

    // There is one signature, so median for this token equals to the min
    require tokensCount() == 1;
    require signaturesCount() == 1;

    setPrices(e, dataStore, eventEmitter, minPrice);

    // Assert the price should be stored in uncompacted format
    
    address token = firstToken();
    uint precision = getPriceFeedMultiplier(e, dataStore, token);
    Price.Props price = getPrimaryPrice(e, token);
    
    assert assert_uint256(minPrice * precision / 10 ^ 30) == price.min;
    
}


