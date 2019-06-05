pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;

    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        bool isOpen;
        mapping(address => uint) buyers;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _website, uint _totalTickets)
        public
        onlyOwner
        returns (uint _id)
    {
        _id = idGenerator;
        events[_id] = Event({
            description: _description,
            website: _website,
            totalTickets: _totalTickets,
            sales: 0,
            isOpen: true
        });
        idGenerator++;
        emit LogEventAdded(_description, _website, _totalTickets, _id);
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */
    function readEvent(uint _id)
        public
        view
        returns (string memory description, string memory website, uint available, uint sales, bool isOpen)
    {
        Event storage selected = events[_id];
        description = selected.description;
        website = selected.website;
        available = selected.totalTickets;
        sales = selected.sales;
        isOpen = selected.isOpen;
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _id, uint _quantity)
        public
        payable
    {
        Event storage selected = events[_id];
        uint total = PRICE_TICKET * _quantity;
        require(selected.isOpen, "Trying to buy a closed event");
        require(total <= msg.value, "Not enough msg.value for total bill");
        require(_quantity <= selected.totalTickets - selected.sales, "Not enough available tickets in stock");

        selected.buyers[msg.sender] += _quantity;
        selected.sales += _quantity;
        uint refund = msg.value - total;
        msg.sender.transfer(refund);
        emit LogBuyTickets(msg.sender, _id, _quantity);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _id)
        public
    {
        Event storage selected = events[_id];
        require(selected.buyers[msg.sender] > 0, "You have not purchased tickets for event");
        uint quantity = selected.buyers[msg.sender];
        selected.sales -= quantity;
        uint refund = quantity * PRICE_TICKET;
        selected.buyers[msg.sender] = 0;
        msg.sender.transfer(refund);
        emit LogGetRefund(msg.sender, _id, quantity);
    }


    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _id)
        public
        view
        returns(uint quantity)
    {
        Event storage selected = events[_id];
        quantity = selected.buyers[msg.sender];
    }


    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _id)
        public
        onlyOwner
    {
        Event storage selected = events[_id];
        selected.isOpen = false;
        uint total = selected.sales * PRICE_TICKET;
        owner.transfer(total);
        emit LogEndSale(msg.sender, total, _id);
    }
}
