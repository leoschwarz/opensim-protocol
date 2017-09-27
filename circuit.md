# Circuits
A circuit consists of a two-way UDP connection, where each side is listening on a socket for new packets and is able to send packets to the peer's socket at the same time.
Circuits are possible between viewer and simulator, simulator and simulator, and simulator and utility server. However for now this spec will only cover circuits between a viewer and simulator.
The notion of trusted and untrusted circuits is not that important in this context, as these circuits are always considered untrusted. Hence messages marked as only acceptable on a trusted circuit are **to be discarded**.

## TODO
* Using first and last name is bad for obvious internationalization issues. Figure out if there already is a way to authenticate with only the full name and document it if possible.
* Determine the actually optional fields in the auth request. Indicate optionality or remove the relevant items.

# Authentication
Before UDP communication can be started, the client has to authenticate to the simulator providing credientals to prove identity.
Authentication with an OpenSimulator server takes place over [XML-RPC](http://xmlrpc.scripting.com/spec.html).

## Request
Call the `login_to_simulator` method via XML-RPC with at least the following arguments.

| Name       | XML-RPC type | Description |
| ---------- | ------------ | ----------- |
| `first`    | String       | The first name of the client. |
| `last`     | String       | The last name of the client. |
| `passwd`   | String       | MD5 hash of the client password, prepended with "$1$". |
| `start`    | String       | "home", "last", or "uri:<region-name>&<x-coord>&<y-coord>&<z-coord>" |
| `version`  | String       | Network client version. |
| `channel`  | String       | Network client identifier. |

## Response

Many values can be returned depending on the endpoint, however at least the following values must be provided on a successful login.

| Name           | XML-RPC type | Description |
| -------------- | ------------ | ----------- |
| `look_at`      | String       | (TODO: Vector encoding.) Unit vector indicating the direction to look at centering the origin at the agent's position.<br>(0, 1, 0) is facing straight north, (1, 0, 0) is east, (0,-1, 0) is south and (-1, 0, 0) is west. |
| `circuit_code` | Int          | To be used, by the client, as an authentication token which proves that the client just successfully authenticated to the authentication endpoint. |
| `session_id`   | String       | Temporary id assigned to this session by the simulator on login, used to verify our identity in packets. |
| `agent_id`     | String       | The agent id identifies the agent in packets. "client" and "avatar" are synonymous to agent. |
| `sim_ip`       | String       | IPv4 address of the simulator to connect to. |
| `sim_port`     | Int          | Port of the simulator to connect to. |

# Circuit establishment
After finishing authentication, the client is supposed to set up a socket and listen on it, then send the following packets to the simulator.

| Packet                         | Sender  | Description                     |
| ------------------------------ | ------- | ------------------------------- |
| `UseCircuitCode`               | client  | Required to verify prior authentication, sending the circuit code from the login response. |
| `CompleteAgentMovement`        | client  | Client notifies the simulator that the avatar is coming into the region. |
| `AgentThrottle`                | client  | TODO, really needed? |
| `AgentUpdate`                  | client  | TODO, really needed? |


* ??? SEND_AGENT_THROTTLE & SEND_AGENT_UPDATES Funktionen
TODO: What packets does the server send what do we have to expect and wait for?

# References
* http://wiki.secondlife.com/wiki/Circuit (accessed 2017-03-26)
* http://opensimulator.org/wiki/SimulatorLoginProtocol (accessed 2017-04-04)

