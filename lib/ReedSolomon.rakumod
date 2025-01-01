unit module ReedSolomon;
# The following is a toy version of ReedSolomon
# inspired by L<Veritasium's take on the subject|https://www.youtube.com/watch?v=w5ebcowAJD8>

constant MODULUS = 101;
multi infix:<m==> (UInt $a, UInt $b) { $a % MODULUS == $b % MODULUS }
multi infix:<m+> (UInt $a, UInt $b) { $a+$b mod MODULUS }
multi infix:<m*> (UInt $a, UInt $b) { $a*$b mod MODULUS }
multi infix:<m/> (UInt $a, UInt $b) { $a m* expmod $b, MODULUS - 2, MODULUS }
multi infix:<m-> (UInt $a, UInt $b) { ($a-$b) mod MODULUS }
multi prefix:<m+>(UInt $x) { +$x mod MODULUS }
multi prefix:<m->(UInt $x) { -$x mod MODULUS }

# https://rosettacode.org/wiki/Polynomial_long_division#Raku
sub poly-long-div ( @n is copy, @d ) {
  return [0], |@n if +@n < +@d;

  my @q = gather while +@n >= +@d {
    @n = @n Z[m-] flat ( ( @d X[m*] take ( @n[0] m/ @d[0] ) ), 0 xx * );
    @n.shift;
  }

  return @q, @n;
}

class Polynomial {
  has UInt @.coefficients;
  has $.coeff-zero = 0;
  has $.coeff-one = 1;
  method stripped-coefficients {
    @!coefficients.map(* % MODULUS)
    .reverse
    .toggle(:off, * > 0)
    .reverse
  }
  method degree returns UInt { @!coefficients.elems }
  method CALL-ME(UInt $x) { @!coefficients.reverse.reduce: * m* $x m+ * }
  method AT-POS(UInt $n) { @!coefficients[$n] // 0 }
}

multi infix:<+>(Polynomial $a, Polynomial $b --> Polynomial) {
  Polynomial.new: coefficients => ($a[$_] m+ $b[$_] for ^max(($a,$b)».degree))
}
multi infix:<->(Polynomial $a, Polynomial $b --> Polynomial) {
  Polynomial.new: coefficients => ($a[$_] m- $b[$_] for ^max(($a,$b)».degree))
}
multi infix:<*>(Polynomial $a, Polynomial $b --> Polynomial) {
  my @coefficients = 0 xx [+] ($a,$b)».degree;
  for ^$a.coefficients -> $i { for ^$b.coefficients -> $j {
    @coefficients[$i+$j] [m+]= $a[$i] m* $b[$j]
  }
  }
  Polynomial.new: :@coefficients;
}
multi infix:<divmod>(Polynomial $a, Polynomial $b) {
  poly-long-div($a.stripped-coefficients.reverse, $b.stripped-coefficients.reverse)
    .map: { Polynomial.new: coefficients => .reverse }
}


constant NUMBER-OF-SYNDROMES = 2;

sub encode(@coefficients) is export {
  my Polynomial $P .=new: coefficients => (0 xx NUMBER-OF-SYNDROMES, @coefficients).flat;

  my ($q, $r) = $P divmod my $d = [*] ^NUMBER-OF-SYNDROMES .map: { Polynomial.new: coefficients => (m-($_+1), 1) }

  die "unexpected result" unless ($P - $q*$d - $r).stripped-coefficients == 0;

  $P - $r

}

# vi: shiftwidth=2 nu
