pragma solidity ^0.4.19;

import "./AbstractBalance.sol";
//ALL DATA VARIABLES ARE SUBJECT TO CHANGE (STC)

contract Pool is AbstractBalance {
  string public publicKey;                          //a public RSA key to encrypt against
  bytes32[] nameServers;
  address owner;                                    //msg.sender = marketplace; therefore we need to pass in an owner manually
  mapping (address => string) dataForNode;          //data for the pool to send its nodes (node_address => data) STC
  string dataForClient;                             //data for the pool to send its nodes (node_address => data) STC

  Client client;                                    //client/website that is employing the pool (1 per pool for Beta)

  mapping (address => Client) private clients;       //client requesting pool for protection/cdn
  mapping (address => Node) private nodes;           //node information (proposal)

  address[] private client_list;                     //list of client proposals
  address[] private node_list;                       //list of node proposals

  // Struct to store node data
  struct Node {
    string publicKey;

    //these will be encrypted in the future and are STC
    string name;
    string email;
    string bio;
    string ip_address;
    string location;
    address wallet_address;
    int status; // 0 = rejected, 1 = approved, 2 = pending
    bool exists;
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
    address wallet_address;
    int status; // 0 = rejected, 1 = approved, 2 = pending
    bool exists;
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
  function getBalanceStructFor(address _user) public view returns (uint256,uint256,uint256,uint256) {
    return (userBalance[_user].owed, userBalance[_user].total, userBalance[_user].completed, userBalance[_user].paid);
  }

  function getTotalBalanceFor(address _client) public view returns (uint) {
    return userBalance[_client].total;
  }

  function getOwedBalanceFor(address _node) public view returns (uint) {
    userBalance[_node].owed;
  }

  function allocateFundsFrom(address _client, uint _amount) public returns (bool) {
      allocateFunds(_amount);

      Balance storage _userBalance = userBalance[_client];

      userBalance[_client] = Balance({
        owed : _userBalance.owed,
        total : _userBalance.total + _amount,
        completed : _userBalance.completed,
        paid : _userBalance.paid
      });

      /* if (userBalance[_client].total != _userBalance.total + _amount) { revert(); } */

      return true;
  }

  /** STC
  * Make a proposal to join this pool (from a node)
  *
  * @param _publicKey for encryption
  * @param _data information about this node
  */
  function applyNode(string _publicKey, string _data) public {
    nodes[msg.sender] = Node({
      publicKey : _publicKey,
      name : _data,
      email: "node@gladius.io",
      bio: "hello world",
      ip_address: "1.1.1.1",
      location: "usa",
      wallet_address: msg.sender,
      status: 2,
      exists: true
    });
    node_list.push(msg.sender);
  }

  /** STC
  * Client calls this to apply to this pool
  *
  * @param _publicKey RSA public key
  * @param _data Application or any information that is being sent from the client to the pool
  */
  function applyClient(string _publicKey, string _data) public {
    clients[msg.sender] = Client({
      publicKey : _publicKey,
      name : _data,
      email: "client@gladius.io",
      bio: "hello world",
      ip_address: "1.1.1.1",
      location: "usa",
      wallet_address: msg.sender,
      status: 2,
      exists: true
    });
    client_list.push(msg.sender);
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

  function getNodeList() constant public returns (address[]) {
    return node_list;
  }

  function getClientList() constant public returns (address[]) {
    return client_list;
  }

  function getPublicKey() public returns (string){
    return publicKey;
  }

  // WIP

  function getNode(address _node) public returns (address){
    return nodes[_node].wallet_address;
  }

  function getClient(address _client) public returns (address){
    return (clients[_client].wallet_address);
  }

  // WIP

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
  * @param _client client
  * @param _newData newData
  */
  function updateClientData(address _client, string _newData) public {
    require(msg.sender == _client);
    clients[_client].name = _newData;
  }

  /**
  * Accept a node
  *
  * @param _node address of the applying node
  */
  function acceptNode(address _node) public {
    require(msg.sender == owner);
    require(nodes[_node].exists);
    nodes[_node].status = 1;
  }

  /**
  * Sets the client for this pool (1 client per pool in Beta)
  *
  * @param _clientAddress clientAddress
  */
  function acceptClient(address _clientAddress) public {
    require(msg.sender == owner);
    require(clients[_clientAddress].exists);
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
    require(nodes[_node].exists);
    nodes[_node].status = 0;
  }

  /**
  * Remove a member
  * Must be the owner
  * @param _client address to be removed
  */
  function rejectClient(address _client) public {
    require(msg.sender == owner);
    require(clients[_client].exists);
    clients[_client].status = 0;
    //$client doesnt change but since it's status is 0 it should still work
  }
}
