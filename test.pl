# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::Find::Similars;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below 

print <<'EOF';

== In testing 2, you should see:
- - >8 - -

## =========
           3 PopupTest.java       test/
           3 CardLayoutTest.java  test/

## =========
           4 BinderyHelloWorld.jpg  test/
           5 MacHelloWorld.gif  test/
- - >8 - -
== Testing 2 begins:
EOF

File::Find::Similars->init(1, [test]);
similarity_check_name();

print "ok 2\n";
