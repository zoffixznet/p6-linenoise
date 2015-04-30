use v6;

use NativeCall;

#| This module provides bindings to linenoise
#| (L<https://github.com/antirez/linenoise>) for Perl 6
#| via NativeCall.
module Linenoise {
    # XXX these belong in separate modules, and are probably Linux-specific
    my constant STDIN_FILENO = 0;
    my constant F_GETFL      = 0x03;
    my constant F_SETFL      = 0x04;
    my constant O_NONBLOCK   = 0x800;

    my sub fcntl(Int $fd, Int $cmd, Int $arg) returns Int is native(Str) { * }
    my sub free(Pointer $p) is native { * }

    #| Completions objects are opaque data structures provided by linenoise
    #| that contain the current list of completions for the completions
    #| request.  See L<#linenoiseAddCompletion> for more details.
    our class Completions is repr('CPointer') {}

    my sub linenoise_raw(Str $prompt) returns Pointer[Str] is native('liblinenoise.so') is symbol('linenoise') { * }

    #| Adds an entry to the current history list.  C<$line> must be C<.defined>!
    our sub linenoiseHistoryAdd(Str $line) is native('liblinenoise.so') is export { * }

    #| Sets the maximum length of the history list.  Entries at the front of this list will be
    #| evicted.
    our sub linenoiseHistorySetMaxLen(int $len) returns int is native('liblinenoise.so') is export { * }

    #| Saves the current history list to a file.
    our sub linenoiseHistorySave(Str $filename) returns int is native('liblinenoise.so') is export { * }

    #| Loads a file and populates the history list from its contents.
    our sub linenoiseHistoryLoad(Str $filename) returns int is native('liblinenoise.so') is export { * }

    #| Clears the screen.
    our sub linenoiseClearScreen() is native('liblinenoise.so') is export { * }

    #| Enables/disables multi line history mode.
    our sub linenoiseSetMultiLine(int $ml) is native('liblinenoise.so') is export { * }

    #| Puts linenoise into key code printing mode (used for debugging).
    our sub linenoisePrintKeyCodes() is native('liblinenoise.so') is export { * }

    #| Sets up a completion callback, invoked when the user presses tab.  The
    #| callback gets the current line, and a completions object.  See
    #| L<#linenoiseAddCompletion> to see how to add completions from within
    #| a callback.
    our sub linenoiseSetCompletionCallback(&callback (Str, Completions)) is native('liblinenoise.so') is export { * }

    #| Adds a completion to the current set of completions.  The first
    #| parameter is the completions object (which is passed into the callback),
    #| and the second is the completion to be added, as a full line.
    #| Completions are offered in the order in which they are provided to this
    #| function, so keep that in mind if you want your users to have a sorted
    #| list of completions.
    our sub linenoiseAddCompletion(Completions $completions, Str $completion) is native('liblinenoise.so') is export { * }

    #| Prompts the user for a line of input after displaying L<$prompt>, and
    #| returns that line.  During this operation, standard input is set to
    #| blocking, and line editing functions provided by linenoise are available.
    our sub linenoise(Str $prompt) returns Str is export {
        my $flags = fcntl(STDIN_FILENO, F_GETFL, 0);

        LEAVE fcntl(STDIN_FILENO, F_SETFL, $flags);

        fcntl(STDIN_FILENO, F_SETFL, $flags +& +^O_NONBLOCK);

        my $p = linenoise_raw($prompt);

        if $p {
            my $line = $p.deref;
            free($p);
            $line;
        } else {
            Str
        }
    }
}

=begin pod

=head1 NAME

Linenoise

=head1 AUTHOR

Rob Hoelz <rob AT hoelz.ro>

=head1 SYNOPSIS

    use Linenoise;

    while (my $line = linenoise '> ').defined {
        say "got a line: $line";
    }

=head1 DESCRIPTION

This module provides bindings to linenoise
(L<https://github.com/antirez/linenoise>) for Perl 6 via NativeCall.

=head1 EXAMPLES

=head2 Basic History

    use Linenoise;

    my constant HIST_FILE = '.myhist';
    my constant HIST_LEN  = 10;

    linenoiseHistoryLoad(HIST_FILE);
    linenoiseHistorySetMaxLen(HIST_LEN);

    while (my $line = linenoise '> ').defined {
        linenoiseHistoryAdd($line);
        say "got a line: $line";
    }

    linenoiseHistorySave(HIST_FILE);

=head2 Tab Completion

    use Linenoise;

    my @commands = <help quit list get set>;

    linenoiseSetCompletionCallback(-> $line, $c {
        my ( $prefix, $last-word ) = find-last-word($line);

        for @commands.grep(/^ "$last-word" /).sort -> $cmd {
            linenoiseHistoryAdd($c, $prefix ~ $cmd);
        }
    });

    while (my $line = linenoise '> ').defined {
        say "got a line: $line";
    }

=end pod
