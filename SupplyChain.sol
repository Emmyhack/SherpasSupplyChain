// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// we import Chainlink's AggregatorV3Interface for retrieving off-chain data
// you can get AggregatorV3Interface by visiting the chainlinK GitHub and search for it
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract SupplyChain {
    // State variables
    address public owner; // The owner of the contract
    AggregatorV3Interface internal priceFeed; // Chainlink price feed interface

    // enum is to know the product status
    enum Status { Created, Shipped, Delivered, Canceled }

    // Struct is to representthe products that are in the supplyChain 
    struct Product {
        string name; // Name of the product
        uint256 price; // Price of the product
        uint256 quantity; // Available product with the manufacturer 
        Status status; // Current status of the product
        bool exists; // Check if the product exists
    }

    // Mapping of product ID to Product struct
    mapping(uint256 => Product) public products;

    // Events are used to log in the actions in the chain
    event ProductAdded(uint256 indexed productId, string name, uint256 price, uint256 quantity);
    event ProductUpdated(uint256 indexed productId, uint256 price, uint256 quantity, Status status);
    event ProductStatusUpdated(uint256 indexed productId, Status status);

    // Constructor to set the Chainlink price feed address
    constructor(address _priceFeed) {
        owner = msg.sender; // Set the contract creator as the owner
        priceFeed = AggregatorV3Interface(_priceFeed); // Initialize the price feed
    }

    // Modifier is used to restrict access of other participants from accessing the function of the other in the chain
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    // Function to add a new product
    function addProduct(uint256 productId, string memory name, uint256 quantity) public onlyOwner {
        require(!products[productId].exists, "Product already exists"); // Ensure product doesn't exist
        uint256 price = getLatestPrice(); // Fetch the latest price from the oracle
        products[productId] = Product(name, price, quantity, Status.Created, true); // Add the product
        emit ProductAdded(productId, name, price, quantity); // Emit event
    }

    // Function to update product details
    function updateProduct(uint256 productId, uint256 quantity) public onlyOwner {
        require(products[productId].exists, "Product does not exist"); // Ensure product exists
        uint256 price = getLatestPrice(); // Fetch the latest price from the oracle
        products[productId].price = price; // Update the price
        products[productId].quantity = quantity; // Update the quantity
        emit ProductUpdated(productId, price, quantity, products[productId].status); // Emit event
    }

    // Function to update the status of a product
    function updateProductStatus(uint256 productId, Status status) public onlyOwner {
        require(products[productId].exists, "Product does not exist"); // Ensure product exists
        products[productId].status = status; // Update the product status
        emit ProductStatusUpdated(productId, status); // Emit event
    }

    // Internal function to get the latest price from the Chainlink oracle
    function getLatestPrice() internal view returns (uint256) {
        (
            /* uint80 roundID */,
            int256 price,
            /* uint256 startedAt */,
            /* uint256 timeStamp */,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData(); // Fetch the latest price data
        require(price > 0, "Price data not available"); // Ensure price data is valid
        return uint256(price); // Return the price as a positive integer
    }

    // Function to withdraw funds (if needed)
    function withdrawFunds() external onlyOwner {
        payable(owner).transfer(address(this).balance); // Transfer contract balance to owner
    }
}
