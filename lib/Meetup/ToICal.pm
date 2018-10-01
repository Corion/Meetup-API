package Meetup::ToICal;
#!perl -w
use strict;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';
use Exporter 'import';
use POSIX qw(strftime);
use Data::ICal::Entry::Event;
use Date::ICal;

our @EXPORT_OK = qw(meetup_to_icalendar get_meetup_event_uid);

our $VERSION = '0.01';

=head1 NAME

Meetup::ToICal - convert Meetup data to ICal data

=head1 SYNOPSIS

  use Meetup::ToICal 'meetup_to_icalendar';
  my $ical = meetup_to_icalendar( $meetup );

=head1 DESCRIPTION

Import meetings from Meetup into iCal or CalDAV.

=head1 FUNCTIONS

=head2 C<< get_meetup_event_uid( $event ) >>

  my $uid = get_meetup_event_uid( $meetup )

Returns a unique identifier for a Meetup event. Currently this is the
Meetup event id plus C<@meetup.com>.

=cut

sub get_meetup_event_uid( $event ) {;
    my $uid = $event->{id} . '@meetup.com';
}

=head2 C<< meetup_to_icalendar( $event ) >>

  my $data = meetup_to_icalendar( $event );

Returns a data structure suitable for inserting to a CalDAV calendar
from a Meetup event.

=cut

sub meetup_to_icalendar( $meetup ) {
    my $uid = get_meetup_event_uid( $meetup );
    if( $meetup->{time} !~ /^(\d+)\d\d\d$/ ) {
        warn "Weirdo timestamp '$meetup->{time}' for event";
        return;
    };
    my $start_epoch = $1;
    
    # We chuck everything into the floating "local" timezone
    my $startTime = strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( $start_epoch + ($meetup->{utc_offset} / 1000)));
    my $createdTime = strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( $meetup->{created} / 1000));

    #use Data::Dumper;
    #warn Dumper $meetup->{venue}->{address_1};
    #use Encode 'encode';
    #$meetup->{venue}->{address_1} = encode('Latin-1',$meetup->{venue}->{address_1});
    #warn "Encoded Latin-1: " . Dumper $meetup->{venue}->{address_1};
    
    my $res = {
        uid      => $uid,
        #summary  => $meetup->{name},
        title    => $meetup->{name},
        #description => $meetup->{description}, # Net::CalDAVTalk doesn't like the encoding sometimes and then crashes
        created => $createdTime,
        start  => $startTime,
        #dtend    => $startTime, 
        #duration => 3600, # Net::CalDAVTalk crashes if we set 'duration'?!
        links => {
            $meetup->{link} => {
                href => $meetup->{link},
                title => 'Meetup Link',
            },
        },
        locations => {
            location => {
                name => join( "\n",
                            grep { /\S/ }
                                $meetup->{venue}->{name},
                                $meetup->{venue}->{address_1},
                                $meetup->{venue}->{city}),
                address => { name => 'address', value => join "\n",
                            grep { /\S/ }
                                $meetup->{venue}->{address_1},
                                $meetup->{venue}->{city}
                            },
            },
        },
    };
}

1;