set opt selfjump_stop 0
set error unknown_code off
step 5000
dump xram 0x0000 0x0050
quit
