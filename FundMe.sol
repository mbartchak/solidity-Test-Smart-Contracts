//SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256; // for <^0.8

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        
        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumUSD, "error msg: not enough ETH");
        
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    //in  wei
    function getPrice() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        
        //can just put commas where unused variables are
        (,int256 answer,,,) = priceFeed.latestRoundData();

        return uint256(answer * 10000000000);
    }

    function getVersion() public view returns (uint256) {
        //we made a contract that conatins all functions of AV3I at the ETH/USD price feed address on Rinkeby testnet
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    //eth amount in wei
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    modifier onlyOwner {
        require(msg.sender == owner); //only want the contract owner
        _;
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
