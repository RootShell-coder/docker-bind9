$ORIGIN example.com.
$TTL  600
@         IN  SOA ns.example.com. noc.example.com. (
                        1       ; serial
                        10800   ; refresh (3 hours)
                        600     ; retry (10 minutes)
                        1209600 ; expire (2 weeks)
                        3600 )  ; minimum (1 hour)
@         IN      NS      ns.example.com.
ns        IN      A       172.18.0.2
www       IN      A       172.18.0.2
