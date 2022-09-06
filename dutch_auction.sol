// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint nftId
    ) external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

    IERC721 public immutable nft;
    uint public immutable nftId;

    address payable public immutable seller;
    uint public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;
    // mapping from bidder to amount of ETH the bidder can withdraw
    mapping(address => uint) public bids;

    constructor(
        address _nft,
        uint _nftId,
        uint _startingBid
    ) {
        nft = IERC721(_nft);
        nftId = _nftId;

        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    function start() external {
        require(msg.sender == seller, "only seller");
        require(!started, "already started");
        
        nft.transferFrom(msg.sender, address(this), nftId);
        started = true;
        endAt = block.timestamp + 7 days;
        
        emit Start();
    }

    function bid() external payable {
        require(msg.value > highestBid, "not enuff dough");
        require(started, "auction hasnt started");
        require(!ended, "auction is kebab");
        
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }
        highestBid = msg.value;
        highestBidder = msg.sender;
        
        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        payable(msg.sender).transfer(bids[msg.sender]);
        emit Withdraw(msg.sender, bids[msg.sender]);
        bids[msg.sender] = 0;
    }

    function end() external {
        require(started, "not started");
        require(block.timestamp >= endAt, "cant close yet");
        require(!ended, "ended already");
        ended = true;
        
        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}
