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

    function createProposal(string calldata _description,uint _amount,address payable _recipient) public validManager() {
        require(totalAmount>=_amount,"Not enough funds!");
        proposals[currProposalId] = Proposal({
            id: currProposalId,
            description: _description,
            amount: _amount,
            recipient: _recipient,
            votes: 0,
            end: block.timestamp+voteTime,
            isExecuted: false
        });
        currProposalId++;
    }

    function voteProposal(uint proposalId) public validInvestor() {
        Proposal storage proposal = proposals[proposalId];
        require(voted[msg.sender][proposalId]==false,"You have already voted for this proposal!");
        require(proposal.end>=block.timestamp,"Voting Time has ended for this proposal!");
        require(proposal.isExecuted==false,"Proposal has already been executed!");
        voted[msg.sender][proposalId] = true;
        proposal.votes += numOfShares[msg.sender];
    }

    function executeProposal(uint proposalId) public  validManager() {
        Proposal storage proposal=proposals[proposalId];
        require(((proposal.votes*100)/totalShares)>=quorum,"Proposal has been rejected as majority does not supports it!");
        proposal.isExecuted = true;
        totalAmount -= proposal.amount;
        payable(proposal.recipient).transfer(proposal.amount);
    }

    function ProposalList() public view returns(Proposal[] memory){
        Proposal[] memory temp = new Proposal[](currProposalId);
        for(uint i=0;i<currProposalId;i++){
        temp[i]=proposals[i];
        }
        return temp;
    }

    function seeInvestorsList() public view returns(address[] memory) {
        return investorsList;
    }
    
}