// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
pragma abicoder v2;


import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";
import "@api3/contracts/v0.8/interfaces/IProxy.sol";


// Master contract for sleepSwap dex
contract SleepSwapMasterDCA is  RrpRequesterV0, Ownable {
    using SafeCast for int256;
    using SafeMath for uint256;

    //manager , who can run execute orders function for settlements
    address public manager;


    //capital gain fee charged on withdrawals
    uint256 public feePercent = 30; // 4 decimal -> 0.03%
    uint256 public feeCollected = 0;

    mapping(address => uint256) public tokenBalances;
    mapping(address => mapping(address => uint256)) public userTokenBalances;
    // 0x7D.  --> API3 --> 300
    // 0x7D.  --> sDAI --> 1700
    // 0x3E.  --> xDAI --> 300
    // 0x3E.  --> ARB --> 2000

    struct Order {
        uint256 orderId;
        address fromAddress;
        address toAddress;
        address user;
        uint256 price;
        uint256 amount;
        bool isBuy;
        uint256 startAt; // block timestamp when this order become valid
        bool open;
        bool executed;
        string orderHash;
    }

    // total orders counts
    uint256 public ordersCount = 0;

    // mappings
    mapping(uint256 => Order) public orders;


    // total positions in the contract
    uint256 public positionsCount = 0;

    // position id ==> order ids
    mapping(uint256 => uint256[]) public positionToOrders;
   // user address -> position id
    mapping(address =>  uint256) public userPosition; // points to current user position

    // mapping to show if user has an active position
    mapping(address => uint16) public hasUserPositionActive;

    // swap initializations
    ISwapRouter public immutable swapRouter;
    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    // airnode mappings
    mapping(bytes32 => bool) public incomingFulfillments;
    mapping(bytes32 => int256[]) public fulfilledData;

    address public proxyAddress;

    //modifiers
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    // events:
    event Staked(
        uint256 positionId,
        address indexed user,
        uint256 amount0,
        uint256 amount1,
        address fromAddress,
        address toAddress,
        uint256 gridSize
    );


    event OrderCreated(
        uint256 orderId,
        address fromToken,
        address toToken,
        address user,
        uint256 price,
        uint256 startAt,
        uint256 amount,
        bool isBuy,
        bool open,
        bool executed,
        string orderHash
    );

    event OrderExecuted(
        uint256 orderId,
        string orderHash,
        uint256 fromAmount,
        uint256 toAmount
    );

    event CancelOrder(address indexed user, uint256 orderId, bool isBuy);
    event Withdraw(
        uint256 positionId,
        address indexed user,
        address  token,
        uint256 amount
    );

    // init contract
    constructor(
        address _manager, ISwapRouter _swapRouter, address _rrpAddress, address _proxyAddress
    ) RrpRequesterV0(_rrpAddress)  {
        manager = _manager;
        swapRouter = _swapRouter;
        proxyAddress = _proxyAddress;
    }

    function addManager(address _manager) public onlyOwner {
        manager = _manager;
    }

  

    // user function to stake funds and start the strategy
    function startStrategyWithDeposit(
        uint256[] memory _startTimes,
        uint256 _amount0,
        uint256 _amount1,
        address _fromTokenAddress,
        address _toTokenAddress
    ) public {

        // todo: add checks before deposits

        // require( hasUserPositionActive[msg.sender] != 0 ,"one position is already active!" );

    
        // Transfer token0 to smart contract
        TransferHelper.safeTransferFrom(
            _fromTokenAddress,
            msg.sender,
            address(this),
            _amount0
        );

        // update user balance after transfer
        userTokenBalances[msg.sender][_fromTokenAddress] += _amount0;
        // userTokenBalances[msg.sender][_toTokenAddress] += _amount1;

        // update token balances in contract
        tokenBalances[_fromTokenAddress] +=  _amount0;



        uint256 gridSize = _startTimes.length;
        uint256 token0ForEachBuyOrder = _amount0.div(gridSize);

        // start new position
        uint256 _positionId = ++positionsCount;


        for (uint256 i = 0; i < _startTimes.length; i++) {

             uint256 _orderId = ++ordersCount;

            Order memory newOrder = Order({
                orderId: _orderId,
                fromAddress: _fromTokenAddress,
                toAddress: _toTokenAddress,
                user: msg.sender,
                price: uint256(0),
                startAt: _startTimes[i],
                amount: token0ForEachBuyOrder,
                isBuy: true,
                open: true,
                executed: false,
                orderHash:'0x'
            });

            orders[_orderId] = newOrder;

            // add order to current position array
             positionToOrders[_positionId].push(_orderId);       

            emit OrderCreated(
                newOrder.orderId,
                newOrder.fromAddress,
                newOrder.toAddress,
                newOrder.user,
                newOrder.price,
                newOrder.startAt,
                newOrder.amount,
                newOrder.isBuy,
                newOrder.open,
                newOrder.executed,
                newOrder.orderHash
            );
        }

        // add current position to user positions
        userPosition[msg.sender] = _positionId;

    
        emit Staked(
            _positionId,
            msg.sender,
            _amount0,
            _amount1,
            _fromTokenAddress,
            _toTokenAddress,
            gridSize
        );
    }

    // start startegy with existing user funds in contract
    function startStrategy(
        uint256[] memory _startTimes,
        uint256 _amount0,
        uint256 _amount1,
        address _fromTokenAddress,
        address _toTokenAddress
    ) public {
    

        require( userTokenBalances[msg.sender][_fromTokenAddress] >= _amount0, "Insufficient token0 bal" );
        // require( hasUserPositionActive[msg.sender] != 0 ,"one position is already active!" );



        uint256 gridSize = _startTimes.length;
        uint256 token0ForEachBuyOrder = _amount0.div(gridSize);
    


        // start new position
        uint256 _positionId = ++positionsCount;

 
        for (uint256 i = 0; i < _startTimes.length; i++) {

             uint256 _orderId = ++ordersCount;

            Order memory newOrder = Order({
                orderId: _orderId,
                fromAddress: _fromTokenAddress,
                toAddress: _toTokenAddress,
                user: msg.sender,
                price: uint256(0),
                startAt:_startTimes[i],
                amount: token0ForEachBuyOrder,
                isBuy: true,
                open: true,
                executed: false,
                orderHash:'0x'
            });

            orders[_orderId] = newOrder;
            
            positionToOrders[_positionId].push(_orderId);

            emit OrderCreated(
                newOrder.orderId,
                newOrder.fromAddress,
                newOrder.toAddress,
                newOrder.user,
                newOrder.price,
                newOrder.startAt,
                newOrder.amount,
                newOrder.isBuy,
                newOrder.open,
                newOrder.executed,
                newOrder.orderHash
            );
        }


        // add current position to user positions
        userPosition[msg.sender] = _positionId;
    
        emit Staked(
            _positionId,
            msg.sender,
            _amount0,
            _amount1,
            _fromTokenAddress,
            _toTokenAddress,
            gridSize
        );
    }


    function readDataFeed()
                public
                view
                returns (int224 value, uint256 timestamp)
            {
                // Use the IProxy interface to read a dAPI via its
                // proxy contract .
                (value, timestamp) = IProxy(proxyAddress).read();
                // If you have any assumptions about `value` and `timestamp`,
                // make sure to validate them after reading from the proxy.
            }
    

        function swapTokenTest(uint256 _amountIn) public view returns (uint256, uint256 ) {

            uint256 feeDeduction = _amountIn.mul(feePercent).div(10000);
            // feeCollected += feeDeduction;
            uint256 _amountInAfterFee = _amountIn - feeDeduction;
            (int256 price, ) = readDataFeed();

            // uint256 decimals = 30;

            uint256 expectedOutputTokens = _amountInAfterFee.div(uint256(price)).mul(10^18).div(10^6).mul(10^18).mul(90).div(100);
            return (expectedOutputTokens, uint256(price));
        }

       function swapToken(
        uint256 _amountIn,
        address _fromToken,
        address _toToken
    ) internal returns (uint256 amountOut) {
        // Fee deduction
        uint256 feeDeduction = _amountIn.mul(feePercent).div(10000);
        feeCollected += feeDeduction;
        uint256 _amountInAfterFee = _amountIn - feeDeduction;

        // (int256 price, ) = readDataFeed();

        //output tokens must be  90% of current oracle price 
        // expected output  = input.div(price).mul(18).div(inputDecimals).mul(outputDecimals).mul(90).div(100)      

        // uint256 expectedOutputTokens = _amountInAfterFee.mul( uint256(price) ).div(10^6).mul(90).div(100);

        // Approve the router to spend USDT.
        TransferHelper.safeApprove(_fromToken, address(swapRouter), _amountInAfterFee);

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _fromToken,
                tokenOut: _toToken,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amountInAfterFee,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // The call to exactInputSingle executes the swap.
        amountOut = ISwapRouter(swapRouter).exactInputSingle(params);
    }





      // only manager
    function executeOrders(int256[] memory _orderIds) public onlyManager {
        for (uint256 i = 0; i < _orderIds.length; i++) {
            require(_orderIds[i] > 0, "Order id must be greater than 0!");
            Order storage selected_order = orders[uint256(_orderIds[i])];
            require(selected_order.open, "Order removed!");

            // require(selected_order.startAt <= block.timestamp, "Order is not ready yet!" );

            // deduct tokens from pool    
            tokenBalances[selected_order.fromAddress] -= selected_order.amount;
            
            // deduct tokens from user balance
            userTokenBalances[msg.sender][selected_order.fromAddress] -= selected_order.amount;


       

            // swap tokens from uniswap
            uint256 token_received = swapToken(
                selected_order.amount,
                selected_order.fromAddress,
                selected_order.toAddress
            );

            // update tokens recieved to order token balance
            selected_order.open  = false;
            selected_order.executed = true;

            // update recieved tokens to contract
            tokenBalances[selected_order.toAddress] += token_received;

            // update recieved tokens to user balance
            userTokenBalances[msg.sender][selected_order.toAddress] += token_received;


        

               // emit event
            emit OrderExecuted(
                selected_order.orderId,
                selected_order.orderHash,
                selected_order.amount,
                token_received
            );
        }
    }


    function updateManager(address _address) public onlyOwner {
        manager = _address;
    }



    // updated by manager when order submitted for execution to fusion api
    function updateOrderStatus(uint256 _orderId, string calldata _orderHash, uint256 _expectedOutput) public onlyManager {

            Order storage currentOrder =    orders[_orderId];

            currentOrder.orderHash = _orderHash;
            currentOrder.executed = true;
            currentOrder.open = false;

            // update contract balances on order execution
            tokenBalances[currentOrder.fromAddress] -= currentOrder.amount;
            tokenBalances[currentOrder.toAddress] += _expectedOutput;

            // update user balances
            userTokenBalances[currentOrder.user][currentOrder.fromAddress] -= currentOrder.amount;
            userTokenBalances[currentOrder.user][currentOrder.toAddress] += _expectedOutput;


             // emit event
            emit OrderExecuted(
                _orderId,
                _orderHash,
                currentOrder.amount,
                _expectedOutput
            );
    }


    
    function stopStrategy() public {

        uint256 _userPosition = userPosition[msg.sender];


        // close orders and transfer funds to respective token mapping
        for(uint i = 0; i <  positionToOrders[_userPosition].length; i++){

            uint256 _orderId = positionToOrders[_userPosition][i];
            orders[_orderId].open = false;
   

            emit CancelOrder(msg.sender,  _orderId , orders[_orderId].isBuy );

        }

    }

    function userAvailableBalance(address _user, address _token) public view returns (uint256) {

        uint256 _userPosition = userPosition[_user];

        uint256[] memory _userOrderIds = positionToOrders[_userPosition];

        uint256 usedBalanceInOrders = 0;
      
        for (uint256 i = 0; i < _userOrderIds.length; i++) {

            if(orders[ _userOrderIds[i] ].fromAddress  == _token && orders[ _userOrderIds[i] ].open ){
                usedBalanceInOrders += orders[ _userOrderIds[i] ].amount;
            }
           
        }


        // return available balance to withdraw
        return  userTokenBalances[_user][_token]-usedBalanceInOrders;

    }

    function withdrawUserFunds(address _token, uint256 _amount) public {

        uint256 _userPosition = userPosition[msg.sender];


        uint256 availableBalance = userAvailableBalance(msg.sender, _token);


        require( _amount <= availableBalance , "Insufficient balance to withdraw!");
        require( _amount <= tokenBalances[_token] , "Contract does not have enough founds atm!");

        // deduct withdrawn balance from user mapping
        userTokenBalances[msg.sender][_token] -= _amount;

        // deduct withdrawn balance from contract mapping
        tokenBalances[_token] -= _amount;

        IERC20(_token).transfer(msg.sender, _amount);

    

        emit Withdraw(
            _userPosition,
            msg.sender,
            _token,
            _amount
        );      
    }


    // ** API3 functions ** //

     // To receive funds from the sponsor wallet and send them to the owner.
    receive() external payable {
        payable(owner()).transfer(address(this).balance);
    }

     // The main makeRequest function that will trigger the Airnode request.
    function makeRequest(
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet,
        bytes calldata parameters

    ) external {
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,                        // airnode address
            endpointId,                     // endpointId
            sponsor,                        // sponsor's address
            sponsorWallet,                  // sponsorWallet
            address(this),                  // fulfillAddress
            this.fulfill.selector,          // fulfillFunctionId
            parameters                      // encoded API parameters
        );
        incomingFulfillments[requestId] = true;
    }

     function fulfill(bytes32 requestId, bytes calldata data)
        external
        onlyAirnodeRrp
    {
        require(incomingFulfillments[requestId], "No such request made");
        delete incomingFulfillments[requestId];
        int256[] memory decodedData = abi.decode(data, (int256[]));
        fulfilledData[requestId] = decodedData;

        // execute orderIds recieved here  
        executeOrders(decodedData);


    }

    // To withdraw funds from the sponsor wallet to the contract.
    function withdraw(address airnode, address sponsorWallet) external onlyOwner {
        airnodeRrp.requestWithdrawal(airnode, sponsorWallet);
    }
}
