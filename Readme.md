## 분석

```solidity
 function testAddQuizACL() public {
        uint quiz_num_before = quiz.getQuizNum();
        Quiz.Quiz_item memory q;
        q.id = quiz_num_before + 1; // q.id = 1
        q.question = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        q.answer = "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        vm.prank(address(1));
        vm.expectRevert();
        quiz.addQuiz(q);
    }

```

- `getQuizNum` 함수를 통해 이전 Quiz num을 받는다.
- Quiz_item의 메모리 변수`q` 를 생성하여 값을 설정하고 address가 1인 주소로 Revert를 예상하며 `addQuiz` 함수를 호출한다.

```solidity
function testGetQuizSecurity() public {
        Quiz.Quiz_item memory q = quiz.getQuiz(1);
        assertEq(q.answer, "");
    }
```

- `getQuiz` 함수를 통해 quizId 값이 1인 quiz를 가져오는데 answer 값이 비어있어야한다.

```solidity
function testAddQuizGetQuiz() public {
        uint quiz_num_before = quiz.getQuizNum();
        Quiz.Quiz_item memory q;
        q.id = quiz_num_before + 1;
        q.question = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        q.answer = "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        quiz.addQuiz(q);
        Quiz.Quiz_item memory q2 = quiz.getQuiz(q.id);
        q.answer = "";
        assertEq(abi.encode(q), abi.encode(q2));
    }
```

- `getQuizNum` 함수를 통해 이전 Quiz num을 가져온다.
- Quiz_item 구조체의 메모리 변수 `q` 를 생성한다.
- `addQuiz` 함수를 통해 설정한 Quiz의 값을 저장한다.
- Quiz_item 구조체의 새 메모리 변수 `q2`를 설정된 q.id를 quizId 값으로 설정하여 생성한다.
- 두 구조체 `q` 와 `q2` 가 같아야한다.

```solidity
  	function testBetToPlayMin() public {
        quiz.betToPlay{value: q1.min_bet}(1);
    }

    function testBetToPlay() public {
        quiz.betToPlay{value: (q1.min_bet + q1.max_bet) / 2}(1);
    }

    function testBetToPlayMax() public {
        quiz.betToPlay{value: q1.max_bet}(1);
    }

    function testFailBetToPlayMin() public {
        quiz.betToPlay{value: q1.min_bet - 1}(1);
    }

    function testFailBetToPlayMax() public {
        quiz.betToPlay{value: q1.max_bet + 1}(1);
    }
```

- `betToPlay` 함수에 대한 테스트를 진행

```solidity
function testMultiBet() public {
        quiz.betToPlay{value: q1.min_bet}(1);
        quiz.betToPlay{value: q1.min_bet}(1);
        assertEq(quiz.bets(0, address(this)), q1.min_bet * 2);
    }
```

- quizId가 1인 `quiz`에 최소 금액으로 배팅을 두번한다.
- `bets`의 0번 index에 배팅금액이 배팅한 금액과 같아야한다.

```solidity
   function testSolve2() public {
        quiz.betToPlay{value: q1.min_bet}(1);
        uint256 prev_vb = quiz.vault_balance();
        uint256 prev_bet = quiz.bets(0, address(this));
        assertEq(quiz.solveQuiz(1, ""), false);
        uint256 bet = quiz.bets(0, address(this));
        assertEq(bet, 0);
        assertEq(prev_vb + prev_bet, quiz.vault_balance());
    }
```

- quizId가 1인 `quiz` 에 최소 금액으로 배팅을 진행
- 이전에 가지고 있던 자금 `quiz.vault_balance()` 과 현재 배팅한 금액 `quiz.bets(0, address(this))` 을 `prev_vb`와 `prev_bet` 에 담는다.
- quizId가 1인 `quiz` 에 정답을 빈칸으로 제출하면 false를 반환해야한다.
- `assertEq(prev_vb + prev_bet, quiz.vault_balance())` 퀴즈를 풀고난 후 자금을 확인하는데, `prev_vb + prev_bet` 값이 `quiz.vault_balance`에 들어있어야 한다.
- 퀴즈를 풀고난 후 배팅 금액이 초기화 되어있는지 확인한다.

```solidity
   function testClaim() public {
        quiz.betToPlay{value: q1.min_bet}(1);
        quiz.solveQuiz(1, quiz.getAnswer(1));
        uint256 prev_balance = address(this).balance;
        quiz.claim();
        uint256 balance = address(this).balance;
        assertEq(balance - prev_balance, q1.min_bet * 2);
    }
```

- quizId 1인 `quiz` 에 최소 배팅을 한 후 정답을 제출한다.
- `claim` 함수를 호출한다.
- 현재 balance - 이전 balance 한 값이 배팅한 금액의 2배를 가지고있어야한다.

## 함수 구현

```solidity
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
```

- `mapping(uint => address)[] public bets`
    - 첫 번째 key는 quizId 값
    - 두 번째 key는 배팅한 유저의 주소
    - value는 배팅한 금액
- `mapping(uint => Quiz_item) public target`
    - key는 quizId
    - value는 저장된 각 Quiz_item 구조체의 정보
- `mapping(address => uint256) public reward`
    - key는 user 주소
    - value는 지급받을 보상 금액

---

- **addPlayer()**
    - 함수를 호출한 주소를 플레이어로 등록하는 함수
- **addQuiz(Quiz_item memory q)**
    - 새로운 퀴즈를 추가하는 함수입니다.
    - `notPlayer` modifier을 통해 등록된 플레이어만 호출할 수 있습니다.
    - 호출 할때마다 quiz count는 증가하는데 이를 통해 새 quizId를 설정한 후 저장
- **getAnswer(uint quizId)**
    - quizId에 대한 퀴즈의 답을 반환하는 함수
- **getQuiz(uint quizId)**
    - quizId에 대한 퀴즈의 정보를 반환하는 함수
    - 제출할 정답은 초기화된 상태로 반환
- **getQuizNum()**
    - 현재 등록된 퀴즈의 총 개수를 반환하는 함수
- **betToPlay(uint quizId)**
    - quizId에 대한 퀴즈에 베팅하는 함수
    - 베팅 금액이 최소와 최대 사이인지 확인
    - 베팅 금액을 기록하고 vault_balance에 추가
- **solveQuiz(uint quizId, string memory ans)**
    - 퀴즈의 답을 제출하는 함수
    - 제출한 답이 맞으면 베팅 금액의 2배를 보상으로 기록하고 true를 반환
    - 틀리면 베팅 금액을 vault_balance에 추가하고 false를 반환
- **claim()**
    - 사용자가 획득한 보상을 청구하는 함수
    - 보상 금액을 0으로 리셋하고 해당 금액을 사용자에게 전송
- **receive()**
    - 이더를 직접 받을 수 있게 하는 함수이며 받은 이더를 vault_balance에 추가합니다.