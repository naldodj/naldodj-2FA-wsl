use strict;
use warnings;
my @pwent = getpwnam('root');
if (!@pwent) {die 'Invalid username: root\n';}
if (crypt($ARGV[0], $pwent[1]) eq $pwent[1]) {
    exit(0);
} else {
    print STDERR 'Invalid password $ARGV[0] for root\n';
    exit(1);
}
