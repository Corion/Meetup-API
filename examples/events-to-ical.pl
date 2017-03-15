#!perl -w
use strict;
use POSIX qw(strftime);
use Meetup::API;
use Data::Dumper;
use Net::CalDAVTalk;

use vars '$VERSION';
$VERSION = '0.01';

=head1 NAME

events-to-ical.pl - import Meetup events to iCal or a CalDAV server

=head1 SYNOPSIS

  events-to-ical.pl --group meetup-group-name [VCard filename or CalDAV URL]

=head1 DESCRIPTION

Import meetings from Meetup into iCal or CalDAV.

Existing events will not be overwritten.

=head1 ARGUMENTS

  --help        print documentation about Options and Arguments
  --version     print version number

=head1 OPTIONS

  --calendar    Name of the CalDAV calendar
  --server      Server of the CalDAV calendar (also, credentials)
  --group       URL name of the Meetup group

=head1 EXAMPLE

  events-to-ical.pl --group 'Perl-User-Groups-Rhein-Main' [VCard filename or CalDAV phonebook URLs]

=cut

use Getopt::Long;
use Pod::Usage;

GetOptions(
    'calendar:s' => \my $davcalendar,
    'server:s' => \my $davserver,
    #'u|user:s' => \my $username,
    #'p|pass:s' => \my $password,
    'g|group:s' => \my $groupname,
    'help!' => \my $opt_help,
    'version!' => \my $opt_version,
) or pod2usage(-verbose => 1) && exit;

pod2usage(-verbose => 1) && exit if $opt_help;
if( $opt_version ) {
    print $VERSION;
    exit;
};

$groupname ||= 'Perl-User-Groups-Rhein-Main';
$davcalendar ||= 'Default';
my $today = strftime '%Y-%m-%dT00:00:01', localtime;
my $meetup = Meetup::API->new();

# Frankfurt am Main
#my ($lat,$lon) = (50.110924, 8.682127);

$meetup->read_credentials;

#print Dumper $meetup->group('Perl-User-Groups-Rhein-Main')->get;
my $events = $meetup->group_events($groupname)->get;

sub entry_is_different {
    my( $entry, $match ) = @_;

    my %numbers = map {
        $_->content => 1,
    } @{ $entry->numbers };

    #my %match_numbers = map {
    #    $_->content => 1,
    #} @{ $match->numbers };

    # check name or number
    # If one of the two is a mismatch, we are different
    #$match->name ne $entry->name
    #    or grep { $numbers{ $_->content } } @{ $c->numbers }
    #} @$entries;
};

sub get_meetup_event_uid {
    my( $event ) = @_;
    my $uid = $event->{id} . '@meetup.com';
}

sub add_event {
    my( $caldav, $calendar, $event ) = @_;
    my $handle = $caldav->NewEvent( $calendar, meetup_to_icalendar( $event ));
}
sub meetup_to_icalendar {
    my( $meetup ) = @_;
    my $uid = get_meetup_event_uid( $meetup );
    if( $event->{time} !~ /^(\d+)\d\d\d$/ ) {
        warn "Weirdo timestamp '$meetup->{time}' for event";
        return;
    };
    my $start_epoch = $1;
    warn sprintf "%s at %s", $meetup->{name}, strftime( '%Y%m%dT%H%M%SZ', gmtime( $start_epoch ));
    return {
        uid      => $uid,
        title    => $meetup->{name},
        start    => strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( $start_epoch )),
        #duration => 3600,
    }
}

if( -f $davcalendar ) {
    require Net::CalDAVTalk;
    die "Don't know how to handle local calendar files yet";
    #my $vcard = Net::CalDAVTalk::VCard->new_fromfile($item);
    #push @contacts, $vcard;
} else {
    require Net::CalDAVTalk;
    my $url = URI::URL->new( $davserver );

    my @userinfo = split /:/, $url->userinfo, 2;
    my $CalDAV = Net::CalDAVTalk->new(
        user => $userinfo[0],
        password => $userinfo[1],
        host => $url->host(),
        port => $url->port(),
        scheme => $url->scheme,
        url => $url->path,
        expandurl => 1,
        logger => sub { warn "DAV: @_" },
    );

    my $calendar = $CalDAV->GetCalendar($davcalendar);
    my $upstream_events = $CalDAV->GetEvents($davcalendar, after => $today );
    my %upstream_events = map {
        $_->{uid} => $_
    } @$upstream_events;
    for my $event (@$events) {
        #use Data::Dumper;
        #warn Dumper $event;
        # Convert new event, for easy comparison
        my $uid = get_meetup_event_uid( $event );
        
        if( $event->{time} !~ /^(\d+)\d\d\d$/ ) {
            warn "Weirdo timestamp '$event->{time}' for event";
            return;
        };
        my $start_epoch = $1;
        my $name = sprintf "%s at %s", $event->{name}, strftime( '%Y%m%dT%H%M%SZ', gmtime( $start_epoch ));

        if( exists $upstream_events{ $uid }) {
            # Well, determine if really different, also determine what changed
            # and then synchronize the two
            #add_event( $calendar, $event );
            print "$name exists\n";
        } else {
            add_event( $CalDAV, $davcalendar, $event );
        };
    };
    #print sprintf "%d seconds taken to sync $url", time - $fb_sync;
};
