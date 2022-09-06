// SPDX-License-Identifier: MIT
/*
    MultiCall is a handy contract that queries multiple contracts
    in a single function call and returns all the results.
*/
pragma solidity ^0.8.13;

contract TestMultiCall {
    function test1() external pure returns (uint) {
        return 1;
    }
    function test2() external pure returns (uint) {
        return 2;
    }
    function test3(uint256 _i) external pure returns (uint256) {
        return _i - 3;
    }
    
    function getTest1() external pure returns (bytes memory) {
        return abi.encodeWithSelector(this.test1.selector);
        //or   abi.encodeWithSignature("func1()");
        
    }
    function getTest2() external pure returns (bytes memory) {
        return abi.encodeWithSelector(this.test2.selector);
        //or   abi.encodeWithSignature("func2()"); 
    }
    function getTest3() external pure returns (bytes memory) {
        // return abi.encodeWithSelector(this.test2.selector);
        return abi.encodeWithSignature("test3(uint256)", 3); 
    }
}

contract MultiCall {
    function multiCall(address[] calldata targets, bytes[] calldata data)
        external
        view
        returns (bytes[] memory)
    {
        require(targets.length == data.length, "mistmatch length");
        
        bytes[] memory results = new bytes[](data.length);
        
        for(uint i=0; i<targets.length;) {
            (bool success, bytes memory response) = targets[i].staticcall(data[i]);
            require(success, "unsuccessfull call");
            
            results[i] = response;
            unchecked{ i++;}
        }

        return results;
    }
}
