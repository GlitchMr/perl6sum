use v6;
BEGIN { @*INC.unshift: './lib'; }

use Test;

plan 18;

use Sum::Adler;
ok(1,'We use Sum::Adler and we are still alive');

class S does Sum::Adler32 does Sum::Marshal::StrOrds does Sum::Partial { }
my S $s .= new();
my $h = $s.finalize("Please to checksum this text");
is $h, 0x96250a8e, "Adler32 (StrOrds) computes expected value";
$h = $s.finalize(".");
is $h, 0xa0e10abc, "append after finalization and get expected value";

class FLFoo does Sum::Fletcher[ :modulusA(17), :modulusB(13), :columnsA(8) ] does Sum::Marshal::Raw { }
my FLFoo $flfoo;
$flfoo .= new();
is $flfoo.finalize(1,2,3,4,5,255), 0xb0f, 'custom Fletcher produces expected value';
is ($flfoo.checkvals),(4,15), 'custom Fletcher check values are as expected';
is $flfoo.finalize(4,15), 0, 'custom Fletcher over data and check values is zero';
is ([+] (for ^221 { $flfoo .= new(); $flfoo.finalize(^250, $_); $flfoo.finalize($flfoo.checkvals)})), 0, 'custom Fletcher checkvals produce zero sum across values sweep.';

class FL16 does Sum::Fletcher16 does Sum::Marshal::Raw { }
my FL16 $fl16;
$fl16 .= new();
is $fl16.finalize(1,2,3,4,5,255), 0x320f, 'Fletcher16 produces expected value';
is ($fl16.checkvals),(190,50), 'Fletcher16 check values are as expected';
is $fl16.finalize(190,50), 0, 'Fletcher16 over data and check values is zero';
is ([+] (for ^255 { $fl16 .= new(); $fl16.finalize(^250, $_); $fl16.finalize($fl16.checkvals)})), 0, 'Fletcher16 checkvals produce zero sum across values sweep.';

# Note for Fletcher32 and Fletcher64 these test values are unverified.
# Mainly because there is not much of an authoritative implementation.
# Note that many implementations of it published -- and perhaps even in
# common use -- seem to be wrong in that they use 8 bit addends instead
# of 16 or 32 bit addends, respectively.

class FL32 does Sum::Fletcher32 does Sum::Marshal::Raw { }
my FL32 $fl32;
$fl32 .= new();
is $fl32.finalize(32760..32780), 0x7f3f8034, 'Fletcher32 produces expected value';
is ($fl32.checkvals),(140,32575), 'Fletcher32 check values are as expected';
is $fl32.finalize(140,32575), 0, 'Fletcher32 over data and check values is zero';

class FL64 does Sum::Fletcher64 does Sum::Marshal::Raw { }
my FL64 $fl64;
$fl64 .= new();
is $fl64.finalize(2147483640..2147483680), 0x8000139e80000200, 'Fletcher64 produces expected value';
is ($fl64.checkvals),(0xffffea60, 0x8000139e), 'Fletcher64 check values are as expected';
is $fl64.finalize(0xffffea60, 0x8000139e), 0, 'Fletcher64 over data and check values is zero';

# Now grab the code in the synopsis from the POD and make sure it runs.
# This is currently complete hackery but might improve when pod support does.
# And also an outputs_ok Test.pm function that redirects $*OUT might be nice.
class sayer {
    has $.accum is rw = "";
    method print (*@s) { $.accum ~= [~] @s }
}
my sayer $p .= new();
{ temp $*OUT = $p; eval $Sum::Adler::Doc::synopsis; }
is $p.accum, $Sum::Adler::Doc::synopsis.comb(/<.after \#\s> (<.ws> <.xdigit>+)+/).join("\n") ~ "\n", 'Code in manpage synopsis actually works';

