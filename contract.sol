// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;
contract DAO{

    struct Proposal{
        uint id;
        string description;
        uint amount;
        address recipient;
        uint votes;
        uint end;
        bool isExecuted;
    }

    mapping(address => bool) public isInvestor;
    mapping(address => uint) public numOfShares;
    address[] public investorsList;
    mapping(address => mapping(uint => bool)) public voted;
    mapping(uint => Proposal) public proposals;
    uint public totalShares;
    uint public totalAmount;
    uint public contributionTime;
    address public manager;
    uint public currProposalId;
    uint public voteTime;
    uint public quorum;

    constructor(uint _contributionTime, uint _voteTime, uint _quorum) {
        require(_quorum<100 && _quorum>0,"Quorum value should be between 0 to 100");
        contributionTime = block.timestamp + _contributionTime;
        voteTime = _voteTime;
        quorum = _quorum;
        manager = msg.sender;
    }

    modifier validInvestor() {
        require(isInvestor[msg.sender],"You are not an investor!");
        _;
    }

    modifier validManager() {
        require(manager==msg.sender,"You are not a manager!");
        _;
    }

    function contribution() public payable {
        require(contributionTime>=block.timestamp,"Contribution Time has Ended!");
        require(msg.value>0,"Please send more than 0 ethereum");
        isInvestor[msg.sender] = true;
        totalShares+=msg.value;
        numOfShares[msg.sender] += msg.value;
        totalAmount+=msg.value;
        investorsList.push(msg.sender);
    }

    function redeemShares(uint amount) public validInvestor() {
        require(numOfShares[msg.sender]>=amount,"You do not have sufficient funds!");
        require(totalAmount>=amount,"Can't withdraw,not sufficient funds available!");
        numOfShares[msg.sender] -= amount;
        if(numOfShares[msg.sender]==0) {
            isInvestor[msg.sender] = false;
        }
        payable(msg.sender).transfer(amount);
        totalAmount -= amount;
    }

    function transferShare(uint amount,address to_address) public validInvestor() {
        require(numOfShares[msg.sender]>=amount,"You do not have sufficient funds!");
        numOfShares[msg.sender] -= amount;
        if(numOfShares[msg.sender]==0) {
            isInvestor[msg.sender] = false;
        }
        numOfShares[to_address] += amount;
        isInvestor[to_address]=true;
        investorsList.push(to_address);
    }
    
}