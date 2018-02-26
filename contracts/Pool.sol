pragma solidity ^0.4.19;

import "./AbstractBalance.sol";

contract Pool is AbstractBalance {

  //ALL DATA VARIABLES ARE SUBJECT TO CHANGE (STC)

  // Data about this pool

  string publicKey;                                 //a public RSA key to encrypt against
  bytes32[] nameServers;
  address owner;                                    //msg.sender = marketplace; therefore we need to pass in an owner manually
  mapping (address => string) dataForNode;          //data for the pool to send its nodes (node_address => data) STC
  string dataForClient;                             //data for the pool to send its nodes (node_address => data) STC

  Client client;                                    //client/website that is employing the pool (1 per pool for Beta)

  mapping (address => Client) clients;              //client requesting pool for protection/cdn
  mapping (address => Node) nodes;                  //node information (proposal)

  address[] private client_list;                    //list of client proposals
  address[] private node_list;                      //list of node proposals

  // Struct to store node data
  struct Node {
    string publicKey;

    //these will be encrypted in the future and are STC
    string name;
    string email;
    string bio;
    string ip_address;
    string location;
    string wallet_address;
    int status = 2; // 0 = rejected, 1 = approved, 2 = pending
  }

  // Struct to store client data
  struct Client {
    string publicKey;

    //these will be encrypted in the future and STC
    string name;
    string email;
    string bio;
    string ip_address;
    string location;
    string wallet_address;
    int status = 2; // 0 = rejected, 1 = approved, 2 = pending
  }

  mapping (address => Balance) userBalance;         //maps a client's address to a balance struct

  /**
  * Create new Pool and assign owner
  *
  * Data is assigned owner and uses the owner's public key
  * @param _publicKey Owner's public RSA key to encrypt against
  * @param _owner Address of the owner
  */
  function Pool(string _publicKey, address _owner) public {
    publicKey = _publicKey;
    owner = _owner;
  }

  //TO BE REVISED BY NATE STC
  function getuserBalance(address _client) public view returns (uint256,uint256,uint256,uint256,uint256,uint256) {
      return (userBalance[_client].total, userBalance[_client].available, userBalance[_client].transactionCosts, userBalance[_client].workable, userBalance[_client].completed, userBalance[_client].withdrawable);
  }

  function withdrawFunds(uint256 _amount, address _user) public {
      withdrawFunds(_amount);

      Balance storage _userBalance = userBalance[_user];

      userBalance[_user] = (Balance({
        total : _userBalance.total - _amount,
        available : _userBalance.available,
        transactionCosts : _userBalance.transactionCosts,
        workable : _userBalance.workable,
        completed : _userBalance.completed,
        withdrawable : _userBalance.withdrawable - _amount
        }));
  }

  function allocateClientFundsFrom(address _client, uint256 _amount) public returns (bool) {
    allocateFunds(_amount);

    Balance storage _userBalance = userBalance[_client]; // Grabs balance or a zeroed out struct

    uint256 availableBalance = (2 * _amount) / 10;
    uint256 withdrawableBalance = (2 * _amount) / 10;
    uint256 transactionBalance = (1 * _amount) / 10;

    uint256 workableBalance = _amount - availableBalance - withdrawableBalance - transactionBalance;

    userBalance[_client] = (Balance({
      total : _userBalance.total + _amount,
      available : _userBalance.available + availableBalance,
      transactionCosts : _userBalance.transactionCosts + transactionBalance,
      workable : _userBalance.workable + workableBalance,
      completed : _userBalance.completed,
      withdrawable : _userBalance.withdrawable + availableBalance
      }));

      return true;
  }
  //TO BE REVISED BY NATE STC

  /** STC
  * Make a proposal to join this pool (from a node)
  *
  * @param _node address of node
  * @param _publicKey for encryption
  * @param _data information about this node
  */
  function applyNode(address _node, string _publicKey, string _data) public {
    nodes[_node] = Node({
      publicKey : _publicKey,
      name : _data
    });

    node_list.push(_node);
  }

  /** STC
  * Client calls this to apply to this pool
  *
  * @param _dataToPool Application or any information that is being sent from the client to the pool
  * @param _publicKey RSA public key
  */
  function applyClient(string _dataToPool, string _publicKey) public {
    client_proposals[msg.sender] = Client({
      publicKey : _publicKey,
      name : _dataToPool //probably take this out
    });
  }

  //STC
  function getNodeData(address _node) constant public returns (string){
    return nodes[_node].name;
  }

  //STC
  function getClientData(address _client) constant public returns (string){
    return clients[_client].name;
  }

  //STC
  function getPoolDataForNode(address _node) constant public returns (string){
    return dataForNode[_node];
  }

  //STC
  function getPoolDataForClient(address _node) constant public returns (string){
    return dataForNode[_node];
  }

  function getNodes() constant public returns (address[]) {
    return node_list;
  }

  function getClients() constant public returns (address[]) {
    return client_list;
  }

  /** STC
  * Update the pool data for a node
  * Must be pool owner to execute
  * @param _node node to update
  * @param _newData data to set for this node
  */
  function updateDataForNode(address _node, string _newData) public {
    require(msg.sender == owner);
    dataForNode[_node] = _newData;
  }

  /**
  * Update the data inside of a node
  * Must be the node to execute
  * @param _node node to update
  * @param _newData data to set for this node
  */
  function updateNodeData(address _node, string _newData) public {
    require(msg.sender == _node);
    nodes[_node].name = _newData;
  }

  /** STC
  * Set the client data variable
  *
  * @param _clientDataIn data to send client
  */
  function updateClientData(address _client, string _newData) public {
    require(msg.sender == _client);
    clients[_client] = _newData;
  }

  /**
  * Accept a node
  *
  * @param _node address of the applying node
  */
  function acceptNode(address _node) public {
    require(msg.sender == owner);
    require(nodes[_node].length != 0);
    nodes[_node].status = 1;
  }

  /**
  * Sets the client for this pool (1 client per pool in Beta)
  *
  * @param _clientAddress
  */
  function acceptClient(address _clientAddress) public {
    require(msg.sender == owner);
    require(clients[_clientAddress].length != 0);
    clients[_clientAddress].status = 1;
    client = clients[_clientAddress];
  }

  /**
  * Remove a member
  * Must be the owner
  * @param _node address to be removed
  */
  function rejectNode(address _node) public {
    require(msg.sender == owner);
    require(nodes[_node].length != 0);
    nodes[_node].status = 0;
  }

  /**
  * Remove a member
  * Must be the owner
  * @param _node address to be removed
  */
  function rejectClient(address node) public {
    require(msg.sender == owner);
    require(clients[_client].length != 0);
    clients[_client].status = 0;
    //$client doesnt change but since it's status is 0 it should still work
  }
}
