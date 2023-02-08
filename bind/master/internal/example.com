$ORIGIN example.com.
$TTL  600
@         IN  SOA ns.example.com. noc.example.com. (
                        1       ; serial
                        10800   ; refresh (3 hours)
                        600     ; retry (10 minutes)
                        1209600 ; expire (2 weeks)
                        3600 )  ; minimum (1 hour)
@         IN      NS      ns.example.com.
ns        IN      A       127.0.0.1
www       IN      A       127.0.0.1
