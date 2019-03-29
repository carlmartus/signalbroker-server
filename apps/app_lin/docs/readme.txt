
Examples on how to test (from localhost)

@header 0x02
@message_sizes 0x04
@node_mode 0x08
@port_host 0x01
@port_client 0x02
@heartbeat 0x10

@logger 0x60

v3 get node mode for device id 2
echo -n '03021234080000' | xxd -r -p | nc -4u -q1 127.0.0.1 4000


v3 heartbeat with one value
echo -n '03021234100003010008' | xxd -r -p | nc -4u -q1 127.0.0.1 4000
echo -n '03021234100006010008020003' | xxd -r -p | nc -4u -q1 127.0.0.1 4000
echo -n '03021234100009010008020003041000' | xxd -r -p | nc -4u -q1 127.0.0.1 4000
echo -n '03021234100009010008020003081000' | xxd -r -p | nc -4u -q1 127.0.0.1 4000

v3 heartbeat without payload
echo -n '03021234100000' | xxd -r -p | nc -4u -q1 127.0.0.1 4000
