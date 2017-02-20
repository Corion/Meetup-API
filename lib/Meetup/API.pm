package Meetup::API;
use strict;
use Moo 2;

use vars qw($VERSION);
$VERSION = '0.01';

=head1 NAME

Meetup::API - interface to the Meetup API

=head1 SYNOPSIS

  use Meetup::API;
  my $meetup = Meetup::API->new();
  my $upcoming = $meetup->


=head1 METHODS

=head2 C<< Meetup::API->new %options >>

=over 4

=item B<< version >>

Allows you to specify the API version. The current
default is C<< v3 >>, which corresponds to the
Meetup API version 3 as documented at
L<http://www.meetup.com/en-EN/meetup_api/docs/>.

=back

=cut

sub new {
    my( $class, %options ) = @_;
    $options{ version } ||= 'v3';
    $class = "$class\::$options{ version }";
    $class->new( %options );
};

=head1 SETUP

=over 4

=item 0. Register with meetup.com

=item 1. Click on their verification email link

=item 2. Visit L<https://secure.meetup.com/de-DE/meetup_api/key/>
to get the API key

=item 4. Create a JSON file named C<meetup.credentials>

This file should live in your
home directory
with the API key:

    {
      "applicationKey": ".............."
    }

=back

=cut

package Meetup::API::v3;
use strict;
use Carp qw(croak);
use Future::HTTP;
use Moo 2;
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use URI::URL;
use URI::Escape;

=head1 NAME

Meetup::API::v3 - Meetup API 

=head1 METHODS

=cut

use vars '$API_BASE';
$API_BASE = 'https://api.meetup.com';

has 'API_BASE' => (
    is => 'lazy',
    default => sub { $API_BASE },
);

has 'user_agent' => (
    is => 'lazy',
    default => sub {
        Future::HTTP->new()
    },
);

has 'json' => (
    is => 'lazy',
    default => sub {
        require JSON::XS;
        JSON::XS->new()->ascii
    },
);

has 'url_map' => (
    is => 'lazy',
    default => sub { {
        boards      => '/%s/boards',
        categories  => '/2/categories',
        cities      => '/2/cities',
        concierge   => '/2/concierge',
        dashboard   => '/2/dashboard',
        discussions => '/{groupname}/boards/{bid}/discussions',
        events      => '/find/events',
        #groups      => '/find/groups',
        group       => '/{urlname}',
        self_groups => '/self/groups',
    } },
);

has 'api_key' => (
    is => 'ro',
);

sub url_for( $self, $item, %options ) {
    # Should URI-escape things here:
    (my $url = $self->url_map->{$item} ) =~ s/\{(\w+)\}/exists $options{$1}? uri_escape delete $options{$1}:$1/ge;
    $url = URI->new( $self->API_BASE . $url );
    $url->query_form( key => $self->api_key, sign => 'true', %options );
    $url
}

sub read_credentials($self,%options) {
    if( ! $options{filename}) {
        my $fn = 'meetup.credentials';
        $options{ config_dirs } ||= [grep { defined $_ && -d $_ } ".",$ENV{HOME},$ENV{USERPROFILE}];
        ($options{ filename }) = map { -f "$_/$fn" ? "$_/$fn" : () } (@{ $options{config_dirs}});
    };
    open my $fh, '<:utf8', $options{ filename }
        or croak "Couldn't read API key from '$options{ filename }' : $!";
    local $/;
    my $cfg = $self->json->decode(<$fh>);
    $self->{api_key} = $cfg->{applicationKey}
}

sub request( $self, $method, $url, %params ) {
    $self->user_agent->http_request(
        $method => $url,
        headers => {
            'Content-Type'  => 'application/x-www-form-urlencoded', # ???
            },
    )->then(sub($body,$headers) {
        Future->done(
            $self->parse_response($body,$headers)
        );
    });
}

# We also allow to simply fetch a signed URL
# yet still handle it through our framework, even if we don't have
# the appropriate api_key.
sub fetch_signed_url( $self, %options ) {
}

sub parse_response($self, $body, $headers) {
    return $self->json->decode($body)
}

sub find_events( $self, %options ) {

}

sub group( $self, $urlname ) {
    # https://www.meetup.com/de-DE/Perl-User-Groups-Rhein-Main/
    $self->request( GET => $self->url_for('group', urlname => $urlname ))
}

1;
