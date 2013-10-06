# ***********************************************************************
# Log                                                                   *
# /fdcc/fdcc_packages/Libraries/Logging/Log.pm                          *
#                                                                       *
# Discussion:                                                           *
#                                                                       *
#                                                                       *
#                                                                       *
# Input:                                                                *
# Output:                                                               *
# Manager: D. Huggins (email removed)                                   *
# Company: Full-Duplex Communications Corporation                       *
# Start:   Thursday, 14 December, 2006                                  *
# Version: 01.30.01                                                     *
# Release: 07.01.10.09:55                                               *
# Status:  Production                                                   *
# ***********************************************************************

# All rights reserved by Full-Duplex Communications Corporation
#                  Copyright 2003 - 2008                       
package Logging::Log;

require 5.004;

$Logging::Log::VERSION = '1.303';
@Logging::Log::ISA = qw(Log);


use strict;

use vars qw/ $VERSION @ISA/;

1;



# 
# ID => str (Opt)
# SubID => str (Opt)
# File => '/path/logfile.name'
# Handle => ref to open file handle
# 
sub new
{
   my $class = shift;
   my %this = @_;
   
   my $self = {};
   
   my %m = ('append' => '>>', 'overwrite' => '>');
   
   $self->{_session}{id} = $this{ID} || '';
   $self->{_session}{subid} = $this{SubID} || $$;
   
   $self->{_level} = _define_level();
   
   $self->{_default}{_lcode} = 2;
   
   $self->{_session}{mode} = $m{$this{Mode}} || '>>';
   
   if($this{File})
   {
      my $file = $self->{_session}{mode}.$this{File};
      
      unless(open(LOGFILE, "$file"))
      {
         $self->{Err} = 1;
         push(@{$self->{Error}}, "Cannot open file $this{File}");
      }
      
      else{$self->{_session}{_io}{h} = \*LOGFILE;}
   }
   
   elsif($this{Handle})
   {
      $self->{_session}{_io}{h} = $this{Handle};
   }
   
   else
   {
      $self->{_session}{_io}{h} = \*STDOUT;
   }
   
   bless $self, $class;
   
   return($self);
}

# $logobj->entry('message to log', [1..7]);
#  Where 2nd arg is opt level. Default is 2 ("MOD_MESG") 
sub entry
{
   my $self  = shift;
   my $str   = shift;
   my $lcode = shift || $self->{_default}{_lcode};
   
   my $fh = $self->{_session}{_io}{h};
   
   print { $fh } &logdate().
      " $self->{_level}{$lcode} \[$self->{_session}{id}\:\:$self->{_session}{subid}\] $str\n";
}

sub close
{
   my $self = shift;
   
   unless(close($self->{_session}{_io}{h}))
   {
      $self->{Err} = 1;
      push(@{$self->{Error}}, "Cannot close log file");
   }
}

sub err
{
   return(shift->{Err});
}

sub errors
{
   my $self = shift;
   
   my @errs = @{$self->{Error}};
   $self->{Err} = 0;
   $self->{Error} = undef;
   
   return(join("\n", @errs));
}

sub setLevel
{
   my $self = shift;
   my %this = @_;
   
   foreach my $level(keys %this){$self->{_level}{$level} = $this{$level};}
   
   $self;
}

sub showLevel
{
   my $self = shift;
   
   my @list;
   
   for(keys %{$self->{_level}}){push(@list, "$_\t$self->{_level}{$_}\n");}
   
   return(@list);
}

sub levels
{
   return(%{shift->{_level}});
}

sub setDefault
{
   my $self = shift;
   my $code = shift;
   
   $self->{_default}{_lcode} = $code;
}

sub showDefault
{
   return(shift->{_default}{_lcode});
}

# --- Keep syslog format --- #
sub logdate
{
   my ($day, $mo, $date, $time, $year) = split( " ", (localtime(int(time))));
   
   # Add leading space if 1-9:
   if($date < 10 ){$date =~s/$date/ $date/}
   
   return("$mo $date $year $time");
}

# --- Create default levels --- #
sub _define_level
{
   return
   (
      {
      1 => "MOD_INIT",
      2 => "MOD_MESG",
      3 => "MOD_WARN",
      4 => "MOD_FAIL",
      5 => "MOD_ACTG",
      6 => "MOD_EXIT",
      7 => "MOD_DBUG",
      },
   );
}

# ----------------------- #
# --- Struct -> $self --- #
# ----------------------- #

# $self = bless( {
#                  '_session' => {
#                                  'mode' => '>>',
#                                  'id' => 'test_log',
#                                  '_io' => {
#                                             'h' => \*::STDOUT
#                                           },
#                                  'subid' => 13951
#                                },
#                  '_default' => {
#                                  '_lcode' => 8
#                                },
#                  '_level' => {
#                                '1' => 'MOD_INIT',
#                                '2' => 'MOD_MESG',
#                                '3' => 'MOD_WARN',
#                                '4' => 'MOD_FAIL',
#                                '5' => 'MOD_ACTG',
#                                '6' => 'MOD_EXIT',
#                                '7' => 'MOD_DBUG',
#                              }
#                }, 'Logging::Log' );


__END__

=pod

=head1 NAME

Logging::Log - Simple Object-oriented logging interface

=head1 SYNOPSIS

    # Object initialization:
    use Logging::Log;
    my $log = Logging::Log->new();
    
    # Pointing to an opened filehandle:
    my $log = Logging::Log->new(Handle => \*F);
    
    # Pointing to a /path/file using the 'overwrite' mode:
    my $log = Logging::Log->new(File => "/tmp/$thisfile.log", Mode => 'overwrite');
    
    # Changing and/or adding to predefined logging levels:
    $log->setLevel(5 => 'MOD_CRIT', 8 => 'MOD_OOPS');
    
    # Logging message to the set default level:
    $log->entry("Here is a standard message. Simple, eh?");
    
    # Logging message to a level index other than the default:
    $log->entry("Here is a Warning message.", 3);
    
    # Changing the default logging level:
    $log->setDefault(8);
    
    # Print a list of the predefined logging levels:
    print $log->showLevel; 
    
    # Close a log that has been opened via a FH or a FQFN:
    $log->close;

=head1 DESCRIPTION

Logging::Log provides the user with a clean, useable-out-of-the-box, 
object based logging interface that shines with simplicity.

There are other good perl based logging facilities available, 
each with their own merits. I chose to build Logging::Log 
because several clients of ours had requested a very simple 
logging interface that could just be "plugged in" and have 
message strings sent to a log in a syslog based format. 
Logging::Log is ready to use right out-of-the-box and has 
just enough custom features to make it usable by everyone.


=head1 Methods

=over 4

=item new()

=over 6

The C<new> method creates a new logging object instance and defines
the attributes of the object.
Attributes are passed as key => value pairs:

=item File => "/tmp/somefile.log"

'File' creates a pointer to a /path/filename for Log::new() to open. If there
are any issues with the open attempt, $log->err will be flagged and any
messages will be available via $log->errors

If neither 'File' or 'Handle' is passed, then the default is *STDOUT

=item Handle => \*OPENFILE

'Handle' accepts a pointer to an already opened file

If neither 'File' or 'Handle' is passed, then the default is *STDOUT

=item Mode => ['overwrite' || 'append']

'Mode' allows the user to set the log to be either overwritten or appended

The default mode is set to 'append'

=item Id => 'string'

'Id' is a parameter to help the user identify a class of logging

A typical log entry might look like:

   Jan  9 2007 13:21:10 MOD_FAIL [test_log::13975] Interface failure at fe7/23

where ID => 'test_log'

The default for Id is set to ''

=item SubId => 'string'

'SubId' is a parameter to help the user identify a sub-class of logging

A typical log entry might look like:

   Jan  9 2007 13:21:10 MOD_FAIL [test_log::13975] Interface failure at fe7/23

where SubId => 13975 

The default for SubId is the process identifier (PID)

=back

=item entry()

=over 6

The C<entry> method simply sends the string passed to it to the log file

   $log->entry("Collisions on e2/12");

This results in the following log entry at the default log level:

   Jan  9 2007 13:21:08 MOD_MESG [test_log::13651] Collisions on e2/12

By passing an additional parameter to entry(), the index of the log level list, 
you can change the logging level to whatever you please.


   $log->entry("Interface failure at fe7/23", 4);

This results in the following log entry at the selected log level (4):

   Jan  9 2007 13:21:10 MOD_FAIL [test_log::13975] Interface failure at fe7/23

There are even methods to customize the levels and to change the default 
level. (see: $log->setLevel() and $log->setDefault() below)

=back

=item setLevel()

=over 6

The C<setLevel> method allows the user to change or add new logging levels

   $log->setLevel(5 => 'MOD_CRIT', 8 => 'MOD_OOPS');

This changes logging level '5' from the standard 'MOD_ACTG' to 'MOD_CRIT' and adds the new level of '8'

=back

=item setDefault()

=over 4

The C<setDefault> method allows the user to change the default logging level to whatever level is
used most frequently

   $log->setDefault(8);

would set the newly defined level to '8' (MOD_OOPS)

So that an entry such as:

   $log->entry("Oh-oh message");

would result in a log entry of:

   Jan  9 2007 13:21:10 MOD_OOPS [test_log::13975] Oh-oh message

(See: the showLevel() method below for viewing the currently set levels)

=back

=item showDefault()

=over 4

The C<showDefault> returns a scalar value of the currently defined default level index

   my $def_idx = $log->showDefault;

=back

=item showLevel()

=over 4

The C<showLevel> method allows the user to view the currently defined level hash

   print $log->showLevel;
   
   1       MOD_INIT
   2       MOD_MESG
   3       MOD_WARN
   4       MOD_FAIL
   5       MOD_ACTG
   6       MOD_EXIT
   7       MOD_DBUG

=back

=item levels()

=over 4

The C<levels> returns a hash containing the key(level index) and the value(level definition)

   my %levels =  $log->levels;

=back

=item close()

=over 4

The C<close> method closes log file associated with selected log object

=back

=item err()

=over 4

The C<err> method returns true if an error has occurred

=back

=item errors()

=over 4

The C<errors> method returns a formatted list of error messages since the last inquiry

=back

=back

=head1 Examples

=over 6

=item my $log = Logging::Log->new(ID => 'Processes', SubID => $VERSION);

=over 4

Create a log object that sends entries to STDIO. 

   $log->entry("test message");

   Jan  9 2007 12:10:52 MOD_MESG [Processes::1.003] test message

=back

=item my $log = Logging::Log->new(File => "/tmp/$thisfile.log", Mode => 'overwrite');

=over 4

Create a log object that sends entries to /tmp/$thisfile.log and overwrites any previous data. 

=back

=item print $log->showLevel; 

=over 4

Print current logging level index list:

   1       MOD_INIT
   2       MOD_MESG
   3       MOD_WARN
   4       MOD_FAIL
   5       MOD_ACTG
   6       MOD_EXIT
   7       MOD_DBUG

=back

=back

=head1 PLATFORMS

Any OS with an installation of perl, v5.6.1 or better

=head1 INSTALLATION

Download the source L<http://www.full-duplex.com/~perl/lib/Logging/Log.pm> and place in any valid root library path. If the directory ./Logging does not exist, create and place Log.pm w/in that directory

=head1 TODO

Perhaps add flexibility in time/date stamping & maybe file IO locking, 
but then this module wouldn't be simple any longer.

=head1 BUGS

None known

=head1 SEE ALSO

perl(1), CPAN - http://search.cpan.org/search?query=log

=head1 SUGGESTIONS/CONTRIBUTIONS

Got a question? Suggestions? Maybe you would like to contribute to our new and growing public archive.
Talk to us at perl.dev@full-duplex.com

=head1 AUTHOR

D. Huggins, (dhuggins AT full-duplex DOT com), L<http://www.full-duplex.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 - 2008 by Full-Duplex Communications, Inc.  All rights reserved. 

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

If you need a copy of the GNU General Public License write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut


