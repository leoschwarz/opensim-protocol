# Packets
An UDP-based message system is used for communication between the client ("viewer") and server ("simulator").
TODO: Separate documentation entry for "messages".

## Packet format
Every packet begins with a six bytes long header.

```
+--------+--------+--------+--------+--------+--------+
| Flags  | Sequence number                   | Extra  |
+--------+--------+--------+--------+--------+--------+
```

* Flags: There are 
