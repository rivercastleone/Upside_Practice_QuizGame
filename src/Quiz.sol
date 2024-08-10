// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz {
    struct Quiz_item{
        uint id;
        string question;
        string answer;
        uint min_bet;
        uint max_bet;
    }
    mapping(uint => Quiz_item) public target;
    mapping(uint => mapping(address => uint256)) public bets;
    mapping(address => uint256) public reward;
    mapping(address => bool) public player;
    uint public vault_balance;
    uint public count;
    address public owner;

    constructor() {
        player[msg.sender]=true;
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }
    modifier notPlayer(){
        require(player[msg.sender]);
        _;
    }
    function addPlayer() public {
        player[msg.sender]=true;
    }
    function addQuiz(Quiz_item memory q) public notPlayer {
        count++;
        q.id = count;
        target[q.id] = q;
    }

    function getAnswer(uint quizId) public view returns (string memory) {
        return target[quizId].answer;
    }

    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        Quiz_item memory q = target[quizId];
        q.answer = ""; 
        return q;
    }

    function getQuizNum() public view returns (uint) {
        return count;
    }

    function betToPlay(uint quizId) public payable {
    Quiz_item memory quiz = target[quizId];
    require(msg.value >= quiz.min_bet && msg.value <= quiz.max_bet);
    bets[quizId - 1][msg.sender] += msg.value; 
    vault_balance += msg.value;
}

   function solveQuiz(uint quizId, string memory ans) public returns (bool) {
    Quiz_item memory quiz = target[quizId];
    uint256 bet = bets[quizId-1][msg.sender];
    bets[quizId-1][msg.sender] = 0;
    if (keccak256(abi.encodePacked(ans)) == keccak256(abi.encodePacked(quiz.answer))){
        reward[msg.sender]+=bet*2;
        return true;
    }
    else{
    vault_balance += bet;
    return false;
    }
}

    function claim() public {
    uint256 r = reward[msg.sender];
    reward[msg.sender]=0;
    msg.sender.call{value: r}("");
    }

     receive() external payable {
         vault_balance += msg.value;
     }
}