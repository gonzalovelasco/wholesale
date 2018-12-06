pragma solidity ^0.5.0;

contract Wholesale {

    struct Participant {
        address _address;
        uint money;
        uint quantity;
        bool active;
    }

    //Status:
    //0 -> active
    //1 -> complete
    //2 -> terminate
    //3 -> cancel
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
        address payable [] participantsAddrress;
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
        require(_quantity > 0, "Error quantity");
        require(_price > 0, "Error price");
        require(_limitDay > 0, "Error limit day");
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

    function addParticipant (uint _orderId, uint quantity) public payable {
        //Validate exists order id
        Order storage _order = orders[_orderId];
        require(_order.status == 0,"Error status");
        require(msg.value % _order.price == 0, "Error mod");
        require(quantity > 0, "Error quantity");
        require(quantity <= _order.quantity - _order.currentQuantity, "Error quantity vs currentQuantity");
        Participant memory participant;
        participant._address = msg.sender;
        participant.money = msg.value;
        participant.quantity = quantity;
        participant.active = true;
        _order.currentQuantity += quantity;
        _order.founds += msg.value;
        _order.totalParticipants++;
        _order.participants[msg.sender] = participant;
        _order.participantsAddrress.push(msg.sender);
        if (_order.currentQuantity == _order.quantity) {
            _order.status = 1;
            emit FinishWholesale(_order.id);
        }
    }

    function removeParticipant (uint _orderId) public {
        //Validate exists order id
        Order storage _order = orders[_orderId];
        require(_order.status == 0,"Error status");
        Participant memory participant = _order.participants[msg.sender];
        require(participant.active);
        participant.active = false;
        _order.quantity -= participant.quantity;
        _order.totalParticipants--;
        _order.founds -= participant.money;
        msg.sender.transfer(participant.money);
    }

    function cancelOrder (uint _orderId) public onlyOrderOwner(_orderId) {
        //Validate exists order id
        Order storage _order = orders[_orderId];
        require(_order.status == 1, "Error status");
        require(_order.totalParticipants > 0, "Error total participants");
        for (uint i = 0; i < _order.participantsAddrress.length; i++) {
            address payable participantAddress = _order.participantsAddrress[i];
            if (_order.participants[participantAddress].active) {
                _order.participants[participantAddress].active = false;
                _order.quantity -= _order.participants[participantAddress].quantity;
                _order.totalParticipants--;
                _order.founds -= _order.participants[participantAddress].money;
                participantAddress.transfer(_order.participants[participantAddress].money);
            }
        }
        _order.status = 3;
        totalOrders--;
    }

    function withdraw (uint _orderId) public onlyOrderOwner(_orderId) {
        Order memory _order = orders[_orderId];
        require(_order.status == 1);
        _order.status = 2;
        msg.sender.transfer(_order.founds);
    }

}
