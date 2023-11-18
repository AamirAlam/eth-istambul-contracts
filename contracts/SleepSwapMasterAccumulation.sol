// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
pragma abicoder v2;


import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



// Master contract for sleepSwap dex
contract SleepSwapMasterAccumulation is Ownable {
    using SafeCast for int256;
    using SafeMath for uint256;

    //manager: execute trx
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

    // swap initializations
    ISwapRouter public immutable swapRouter;
    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

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
        address _manager, ISwapRouter _swapRouter
    ) {
        manager = _manager;
        swapRouter = _swapRouter;
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
    
        // Transfer token0 to smart contract
        TransferHelper.safeTransferFrom(
            _fromTokenAddress,
            msg.sender,
            address(this),
            _amount0
        );

        // // transfer token1 to smart contract
        // TransferHelper.safeTransferFrom(
        //     _toTokenAddress,
        //     msg.sender,
        //     address(this),
        //     _amount1
        // );

        // update user balance after transfer
        userTokenBalances[msg.sender][_fromTokenAddress] += _amount0;
        // userTokenBalances[msg.sender][_toTokenAddress] += _amount1;

        // update token balances in contract
        tokenBalances[_fromTokenAddress] +=  _amount0;
        // tokenBalances[_toTokenAddress] +=  _amount1;


        uint256 gridSize = _startTimes.length;
        uint256 token0ForEachBuyOrder = _amount0.div(gridSize);
        // uint256 token1ForEachSellOrder = _amount1.div(gridSize);

        // start new position
        uint256 _positionId = ++positionsCount;


        // // creating sell orderbooks
        // for (uint256 i = 0; i < gridSize; i++) {
           
        //     uint256 _orderId = ++ordersCount;
           
        //     Order memory newOrder = Order({
        //         orderId: _orderId,
        //         fromAddress: _fromTokenAddress,
        //         toAddress: _toTokenAddress,
        //         user: msg.sender,
        //         price: _sellPrices[i],
        //         amount: token1ForEachSellOrder,
        //         isBuy: false,
        //         open: true,
        //         executed: false,
        //         orderHash: "0x" // add dummy string initially for order hash
        //     });

        //     orders[_orderId] = newOrder;

        //     positionToOrders[_positionId].push(_orderId);
        //     // userOrders[msg.sender].push(_orderId);

        //     // emit event
        //     emit OrderCreated(
        //         newOrder.orderId,
        //         newOrder.fromAddress,
        //         newOrder.toAddress,
        //         newOrder.user,
        //         newOrder.price,
        //         newOrder.amount,
        //         newOrder.isBuy,
        //         newOrder.open,
        //         newOrder.executed,
        //         newOrder.orderHash
        //     );
        // }

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
            // userOrders[msg.sender].push(_orderId);

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
            // userOrders[msg.sender].push(_orderId);

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

    

       function swapToken(
        uint256 _amountIn,
        address _fromToken,
        address _toToken
    ) internal returns (uint256 amountOut) {
        // Fee deduction
        uint256 feeDeduction = _amountIn.mul(feePercent).div(10000);
        feeCollected += feeDeduction;
        uint256 _amountInAfterFee = _amountIn - feeDeduction;

     

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
    function executeOrders(uint256[] memory _orderIds) public onlyManager {
        for (uint256 i = 0; i < _orderIds.length; i++) {
            require(_orderIds[i] > 0, "Order id must be greater than 0!");
            Order storage selected_order = orders[_orderIds[i]];
            require(selected_order.open, "Order removed!");
         

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

        for(uint i = 0; i <  positionToOrders[_userPosition].length; i++){

            uint256 _orderId = positionToOrders[_userPosition][i];
            orders[_orderId].open = false;

            emit CancelOrder(msg.sender,  _orderId , orders[_orderId].isBuy );

        }

    }

    function userAvailableBalance(address _token) public view returns (uint256) {


        uint256 _userPosition = userPosition[msg.sender];

        uint256[] memory _userOrderIds = positionToOrders[_userPosition];

        uint256 usedBalanceInOrders = 0;
        // uint256 token_amount_to_return = 0;
        //close existing open orders
        for (uint256 i = 0; i < _userOrderIds.length; i++) {

            if(orders[ _userOrderIds[i] ].fromAddress  == _token && orders[ _userOrderIds[i] ].open ){
                usedBalanceInOrders += orders[ _userOrderIds[i] ].amount;
            }
           
        }

        return  userTokenBalances[msg.sender][_token]-usedBalanceInOrders;

    }

    function withdrawUserFunds(address _token, uint256 _amount) public {

        uint256 _userPosition = userPosition[msg.sender];

        uint256[] memory _userOrderIds = positionToOrders[_userPosition];

        uint256 usedBalanceInOrders = 0;
        // uint256 token_amount_to_return = 0;
        //close existing open orders
        for (uint256 i = 0; i < _userOrderIds.length; i++) {

            if(orders[ _userOrderIds[i] ].fromAddress  == _token && orders[ _userOrderIds[i] ].open ){
                usedBalanceInOrders += orders[ _userOrderIds[i] ].amount;
            }
           
        }

        require( _amount <= userTokenBalances[msg.sender][_token]-usedBalanceInOrders , "Insufficient balance to withdraw!");



        IERC20(_token).transfer(msg.sender, _amount);

    

        emit Withdraw(
            _userPosition,
            msg.sender,
            _token,
            _amount
        );      
    }
}
