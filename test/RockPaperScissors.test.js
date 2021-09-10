const RockPaperScissors = artifacts.require('RockPaperScissors');
const truffleAssert = require('truffle-assertions');

const Web3 = require('web3');
const provider = new Web3.providers.HttpProvider("HTTP://127.0.0.1:7545");
const web3 = new Web3(provider);

let instance;

beforeEach(async () => {
    instance = await RockPaperScissors.new();
});

contract('RockPaperScissors', accounts => {
    it('should built correctly', async() => {
        let games = await instance.games;

        assert.equal(games.length, 0);
    });
    it('enroll with not enough ether', async() => {
        await truffleAssert.reverts(
            instance.enroll({ value: web3.utils.toWei('0.01', 'ether') }),
            "You didn't send enough ether"
        );
    });
    it('enroll twice with the same account', async() => {
        await instance.enroll({ from: accounts[1], value: web3.utils.toWei('0.015', 'ether') });
        await instance.enroll({ from: accounts[2], value: web3.utils.toWei('0.015', 'ether') });

        await truffleAssert.reverts(
            instance.enroll({ from: accounts[1], value: web3.utils.toWei('0.015', 'ether') }),
            "You've already enrolled"
        );
    });
    it('play without enrolled', async() => {
        await truffleAssert.reverts(
            instance.play(0, { from: accounts[1], value: web3.utils.toWei('0.025', 'ether') }),
            "You've not enrolled yet"
        );
    });
    it('play with not enough ether', async() => {
        await instance.enroll({ from: accounts[1], value: web3.utils.toWei('0.015', 'ether') });

        await truffleAssert.reverts(
            instance.play(0, { from: accounts[1], value: web3.utils.toWei('0.02', 'ether') }),
            "You didn't send enough ether"
        );
    });
    it('win player 1', async() => {
        await instance.enroll({ from: accounts[1], value: web3.utils.toWei('0.015', 'ether') });
        await instance.enroll({ from: accounts[2], value: web3.utils.toWei('0.015', 'ether') });

        await instance.play(0, { from: accounts[1], value: web3.utils.toWei('0.025', 'ether') });
        await instance.play(2, { from: accounts[2], value: web3.utils.toWei('0.025', 'ether') });
        
        let player1 = await instance.playersEnrolled(accounts[1]);
        let player2 = await instance.playersEnrolled(accounts[2]);
        let totalGames = await instance.totalGames();
        let games = await instance.games(0);

        assert.equal(player1.player, accounts[1]);
        assert.equal(player2.player, accounts[2]);
        assert.equal(player1.enrolled, true);
        assert.equal(player2.enrolled, true);
        assert.equal(player1.amount, web3.utils.toWei('0.045', 'ether'));
        assert.equal(player2.amount, 0);
        assert.equal(totalGames, 1);
        assert.equal(games[0][0], accounts[1]);
        assert.equal(games[0][1], web3.utils.toWei('0.025', 'ether'));
        assert.equal(games[0][2], 0);
        assert.equal(games[1][0], accounts[2]);
        assert.equal(games[1][1], web3.utils.toWei('0.025', 'ether'));
        assert.equal(games[1][2], 2);
    });
});