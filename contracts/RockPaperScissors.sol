// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import './Ownable.sol';

contract RockPaperScissors is Ownable {

    enum Weapon{ ROCK, PAPER, SCISSORS }

    struct Player {
        address player;
        uint amount;
        bool enrolled;
    }

    struct PlayerInGame {
        address player;
        uint bet;
        Weapon weapon;
    }

    struct Game {
        PlayerInGame player1;
        PlayerInGame player2;
    }

    mapping(address => Player) public playersEnrolled;
    Game[] public games;

    uint paymentToEnroll = 0.015 ether;
    uint paymentToPlay = 0.025 ether;

    modifier enrolled() {
        Player memory player = playersEnrolled[msg.sender];
        require(player.enrolled, "You've not enrolled yet");
        _;
    }

    function enroll() public payable {
        require(msg.value >= paymentToEnroll, "You didn't send enough ether");
        Player storage player = playersEnrolled[msg.sender];
        require(!player.enrolled, "You've already enrolled");
        player.player = msg.sender;
        player.enrolled = true;
    }

    function play(Weapon weapon) public payable enrolled returns(bool) {
        Player storage player = playersEnrolled[msg.sender];
        if (player.amount >= paymentToPlay) {
            player.amount-=paymentToPlay;
        } else {
            require(msg.value >= paymentToPlay, "You didn't send enough ether");
        }

        uint totalGames = games.length;
        if (totalGames == 0) {
            newGame(weapon);
            return false;
        }
        Game storage lastGame = games[totalGames-1];
        if (lastGame.player2.player == address(0)) {
            require(msg.sender != lastGame.player1.player);
            finishGame(weapon, lastGame);
            return true;
        } else {
            newGame(weapon);
            return false;
        }
    }

    function newGame(Weapon weapon) private {
        Game memory game;
        game.player1 = PlayerInGame(msg.sender, msg.value, weapon);
        games.push(game);
    }

    function finishGame(Weapon weapon, Game storage game) private {
        game.player2 = PlayerInGame(msg.sender, msg.value, weapon);
        int result = whoWin(game);
        uint amount = percentage(game.player1.bet + game.player2.bet, 90);
        if (result > 0) {
            playersEnrolled[game.player1.player].amount+=amount;
        } else if (result < 0) {
            playersEnrolled[game.player2.player].amount+=amount;
        } else {
            uint half = percentage(amount, 50);
            playersEnrolled[game.player1.player].amount+=half;
            playersEnrolled[game.player2.player].amount+=half;
        }
    }

    function whoWin(Game memory game) private pure returns(int) {
        return whoWin(game.player1.weapon, game.player2.weapon);
    }

    /**
    Si retorna 0 hay empate
    Si retorna 1 gano home
    Si retorna -1 gano away
     */
    function whoWin(Weapon home, Weapon away) private pure returns(int) {
        if (home == away) {
            return 0;
        }
        if (home == Weapon.ROCK) {
            if (away == Weapon.PAPER) {
                return -1;
            } else {
                return 1;
            }
        }
        if (home == Weapon.PAPER) {
            if (away == Weapon.SCISSORS) {
                return -1;
            } else {
                return 1;
            }
        }
        if (home == Weapon.SCISSORS) {
            if (away == Weapon.ROCK) {
                return -1;
            } else {
                return 1;
            }
        }
        return 0;
    }

    function percentage(uint value, uint percent) private pure returns(uint) {
        return (value * percent) / 100;
    }

    function getAmount() public view returns(uint) {
        return playersEnrolled[msg.sender].amount;
    }

    function redeemAmount() public enrolled payable {
        Player storage player = playersEnrolled[msg.sender];
        payable(msg.sender).transfer(player.amount);
        player.amount = 0;
    }

    function isEnrolled() public view returns(bool) {
        Player memory player = playersEnrolled[msg.sender];
        return player.enrolled;
    }

    function getContractBalance() public onlyOwner view returns(uint) {
        address contractAddress = address(this);
        return contractAddress.balance;
    }

    function totalGames() public view returns(uint) {
        return games.length;
    }

}
