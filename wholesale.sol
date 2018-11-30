pragma solidity ^0.5.0;

contract Wholesale {

    struct Participant {
        address _address;
        uint money;
        uint quantity;
        bool active;
    }

    struct Order {
        uint id;
        uint price;
        uint quantity;
        uint currentQuantity;
        uint limitDay;
        uint founds;
        uint mode;
        uint status;
        address owner;
        uint totalParticipants;
        mapping (address => Participant) participants;
    }

    event FinishWholesale (
        uint orderId
    );

    Order[] orders;
    uint private totalOrders;

    modifier onlyOrderOwner (uint orderId) {
        require(orders[orderId].owner == msg.sender);
        _;
    }

    constructor () public {
    }

    function createOrder (uint _price, uint _quantity, uint _limitDay, uint _mode) public returns (uint) {

        Order memory newOrder;
        newOrder.price = _price;
        newOrder.quantity = _quantity;
        newOrder.currentQuantity = 0;
        newOrder.limitDay = _limitDay;
        newOrder.mode = _mode;
        newOrder.status = 0;
        newOrder.id = ++totalOrders;
        newOrder.owner = msg.sender;
        orders.push(newOrder);
        return newOrder.id;

    }

    function addParticipant (uint _orderId) public payable {
        //Validate exists order id
        Order storage _order = orders[_orderId];
        require(_order.status == 0);
        require(msg.value % _order.price == 0);
        uint quantity = msg.value / _order.price;
        require(quantity > 0);
        require(quantity <= _order.quantity - _order.currentQuantity);
        Participant memory participant;
        participant._address = msg.sender;
        participant.money = msg.value;
        participant.quantity = quantity;
        participant.active = true;
        _order.currentQuantity += quantity;
        _order.founds += msg.value;
        _order.totalParticipants++;
        _order.participants[msg.sender] = participant;
        if (_order.currentQuantity == _order.quantity) {
            _order.status = 1;
            emit FinishWholesale(_order.id);
        }
    }

    function removeParticipant (uint _orderId) public {
        //Validate exists order id
        Order storage _order = orders[_orderId];
        Participant memory participant = _order.participants[msg.sender];
        require(participant.active);
        participant.active = false;
        _order.quantity -= participant.quantity;
        _order.totalParticipants--;
        _order.founds -= participant.money;
        msg.sender.transfer(participant.money);
    }

    function cancelOrder (uint _orderId) public {
    }

    function withdraw (uint _orderId) public onlyOrderOwner(_orderId) {
        Order memory _order = orders[_orderId];
        require(_order.status == 1);
        _order.status = 2;
        msg.sender.transfer(_order.founds);
    }
}
