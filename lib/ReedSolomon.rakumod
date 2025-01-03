unit module ReedSolomon;
# The following is a toy version of ReedSolomon
# inspired by L<Veritasium's take on the subject|https://www.youtube.com/watch?v=w5ebcowAJD8>

constant MODULUS = 101;
multi infix:<==> (UInt $a, UInt $b) { callwith $a % MODULUS, $b % MODULUS }
multi infix:<+>  (UInt $ , UInt $ ) { callsame() mod MODULUS }
multi infix:<*>  (UInt $ , UInt $ ) { callsame() mod MODULUS }
multi infix:</>  (UInt $a, UInt $b) { $a * expmod $b, MODULUS - 2, MODULUS }
multi infix:<->  (UInt $ , UInt $ ) { callsame() mod MODULUS }
multi prefix:<+>(UInt $) { callsame() mod MODULUS }
multi prefix:<->(UInt $) { callsame() mod MODULUS }

# https://rosettacode.org/wiki/Polynomial_long_division#Raku
sub poly-long-div ( @n is copy, @d ) {
  return [0], |@n if +@n < +@d;

  my @q = gather while +@n >= +@d {
    @n = @n Z[-] flat ( ( @d X[*] take ( @n[0] / @d[0] ) ), 0 xx * );
    @n.shift;
  }

  return @q, @n;
}

class Polynomial {
  has UInt @.coefficients;
  has $.coeff-zero = 0;
  has $.coeff-one = 1;
  method list {
    @!coefficients.map(* % MODULUS)
    .reverse
    .toggle(:off, * > 0)
    .reverse
  }
  method size returns UInt { @!coefficients.elems  }
  method CALL-ME(UInt $x) { self.list.reverse.reduce: * * $x + * }
  method AT-POS(UInt $n) { @!coefficients[$n] // 0 }
}

multi infix:<+>(Polynomial $a, Polynomial $b --> Polynomial) {
  Polynomial.new: coefficients => ($a[$_] + $b[$_] for ^max(($a,$b)».size))
}
multi infix:<->(Polynomial $a, Polynomial $b --> Polynomial) {
  Polynomial.new: coefficients => ($a[$_] - $b[$_] for ^max(($a,$b)».size))
}
multi infix:<*>(Polynomial $a, Polynomial $b --> Polynomial) {
  my @coefficients = 0 xx [+] ($a,$b)».size;
  for ^$a.coefficients -> $i { for ^$b.coefficients -> $j { @coefficients[$i+$j] [+]= $a[$i] * $b[$j] } }
  Polynomial.new: :@coefficients;
}
multi infix:<divmod>(Polynomial $a, Polynomial $b) {
  poly-long-div($a.list.reverse, $b.list.reverse)
    .map: { Polynomial.new: coefficients => .reverse }
}


constant DEFAULT-NUMBER-OF-SYNDROMES = 2;
constant @SYNDROME-LOCATIONS = 1, |[\*] 2 xx *;

our sub encode(Blob $coefficients, UInt :$number-of-syndromes where 1..MODULUS = DEFAULT-NUMBER-OF-SYNDROMES) {
  my Polynomial $P .=new: coefficients => (0 xx $number-of-syndromes, $coefficients.list).flat;

  my ($q, $r) = $P divmod my $d = [*] @SYNDROME-LOCATIONS.head($number-of-syndromes).map: { Polynomial.new: coefficients => (-$_, 1) }

  fail "long division failed" unless ($P - $q*$d - $r).list == 0;

  ($P - $r).list.rotor(2, *);
}

our sub check((@a, @b)) {
  my Polynomial $P .=new: coefficients => (@a, @b).flat;
  fail "check failed" unless @SYNDROME-LOCATIONS.head(@a.elems).map({$P($_)}).all == 0;
}

# vi: shiftwidth=2 nu
