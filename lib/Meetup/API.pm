package Meetup::API;
use strict;

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
    # Once we spin ut v3 from this file
    (my $fn = $class) =~ s!::!/!g;
    require "$fn.pm";
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

1;