$TTL 86400
@ IN SOA ns.example.com. noreply.example.com. (
    2023121901 ; serial
    3600       ; refresh
    1800       ; retry
    604800     ; expire
    86400      ; minimum
)

@ IN NS ns.example.com.
ns IN A 127.0.0.1
@ IN A 127.0.0.1
