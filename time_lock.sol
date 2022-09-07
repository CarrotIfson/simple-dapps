/*
TimeLock is a contract where transactions must be queued for some minimum time before it can be executed.
Usually used in DAOs to increase transparency. 
Call to critical functions are restricted to time lock.
This give users time to take action before the transaction is executed by the time lock.

pragma solidity ^0.8.13;
contract TestTimeLock {
    address public timeLock;
    bool public canExecute;
    bool public executed;

    constructor(address _timeLock) {
        timeLock = _timeLock;
    }

    fallback() external {}

    function func() external payable {
        require(msg.sender == timeLock, "not time lock");
        require(canExecute, "cannot execute this function");
        executed = true;
    }

    function setCanExecute(bool _canExecute) external {
        canExecute = _canExecute;
    }
}
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TimeLock {
    event Queue(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Execute(
        bytes32 indexed txId,
        address indexed target,
        uint value,
        string func,
        bytes data,
        uint timestamp
    );
    event Cancel(bytes32 indexed txId);

    uint public constant MIN_DELAY = 10; // seconds
    uint public constant MAX_DELAY = 1000; // seconds
    uint public constant GRACE_PERIOD = 1000; // seconds

    address public owner;
    // tx id => queued
    mapping(bytes32 => bool) public queued;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function getTxId(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_target, _value, _func, _data, _timestamp));
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @param _target Address of contract or account to call
     * @param _value Amount of ETH to send
     * @param _func Function signature, for example "foo(address,uint256)"
     * @param _data ABI encoded data send.
     * @param _timestamp Timestamp after which the transaction can be executed.
     */
    function queue(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external onlyOwner returns (bytes32 txId) {
        require(_timestamp >= block.timestamp + MIN_DELAY, "too soon");
        require(_timestamp < block.timestamp + MAX_DELAY, "too late");
        txId = getTxId(_target, _value, _func, _data, _timestamp);
        require(!queued[txId], "tx already queued");
        queued[txId] = true;
        
        emit Queue(txId, _target, _value, _func, _data, _timestamp);
    }

    function execute(
        address _target,
        uint _value,
        string calldata _func,
        bytes calldata _data,
        uint _timestamp
    ) external payable onlyOwner returns (bytes memory) {
        bytes32 txId = getTxId(_target, _value, _func, _data, _timestamp); 
        require(queued[txId], "tx not queued");
        require(block.timestamp > _timestamp, "not enuff time passed");
        require(block.timestamp <= _timestamp+GRACE_PERIOD, "too late");
        
        queued[txId] = false;
        
        bytes memory data;
        //if tx calls a function
        if(bytes(_func).length > 0) {
            // data = func selector + _data
            data = abi.encodePacked(bytes4(keccak256(bytes(_func))), _data);
        } else {
            // call fallback with data
            data = _data;
        }
        (bool success, bytes memory res) = _target.call{value: _value}(data); 
        require(success, "tx failed");
        
        emit Execute(txId, _target, _value, _func, _data, _timestamp);
        return res;

    }

    function cancel(bytes32 _txId) external onlyOwner{  
        require(queued[_txId], "tx not queued");
        
        queued[_txId] = false;
        emit Cancel(_txId);
    }
}
