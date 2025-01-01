unit module ReedSolomon;
# The following is a toy version of ReedSolomon
# inspired by L<Veritasium's take on the subject|https://www.youtube.com/watch?v=w5ebcowAJD8>

# modular inverse
multi postfix:<⁻¹>(UInt $n) returns UInt {
  if $*modulus.is-prime { expmod $n, $*modulus - 2, $*modulus }
  else {
    my ($i, $h, $v, $d) = $*modulus, $n, 0, 1;
    repeat {
      my $t = $i div $h;
      my $x = $h;
      $h = $i - $t*$x;
      $i = $x;
      $x = $d;
      $d = $v - $t*$x;
      $v = $x;
    } while $h > 0;
    $v mod $*modulus;
  }
}

multi infix:</>(Int $a, UInt $b) returns UInt { $a*$b⁻¹ mod $*modulus }

{
  multi infix:<==>(UInt $a, UInt $b)          { callwith ($a - $b) mod $*modulus, 0 }
  multi infix:<+> (UInt $a, UInt $b --> UInt) { callsame() mod $*modulus }
  multi infix:<*> (UInt $a, UInt $b --> UInt) { callsame() mod $*modulus }
  multi infix:<**>(UInt $a, UInt $b --> UInt) { expmod $a, $b, $*modulus }

  {
    multi prefix:<->(UInt $n          --> UInt) { callsame() mod $*modulus }
    multi infix:<-> (UInt $a, UInt $b --> UInt) { callsame() mod $*modulus }

    say -1;

    # https://rosettacode.org/wiki/Polynomial_synthetic_division#Raku
    sub synthetic-division ( @numerator, @denominator ) {
	my @result = @numerator;
	my $end    = @denominator.end;

	for ^(@numerator-$end) -> $i {
	    @result[$i]    /= @denominator[0];
	    @result[$i+$_] -= @denominator[$_] * @result[$i] for 1..$end;
	}

	'quotient' => @result[0 ..^ *-$end],
	'remainder' => @result[*-$end .. *];
    }

    class Polynomial {
      has UInt @.coefficients;
      has $.coeff-zero = 0;
      has $.coeff-one = 1;
      method degree returns UInt { @!coefficients.elems }
      method CALL-ME(UInt $x) { @!coefficients.reverse.reduce: * * $x + * }
      method AT-POS(UInt $n) { @!coefficients[$n] // 0 }
    }

    multi infix:<==>(Polynomial $a, Polynomial $b) {
      $a.degree == $b.degree and [==] $a.coefficients Z== $b.coefficients
    }
    multi infix:<+>(Polynomial $a, Polynomial $b --> Polynomial) {
      Polynomial.new:
	coefficients => ($a[$_] + $b[$_] for ^max(($a,$b)».degree))
    }
    multi infix:<->(Polynomial $a, Polynomial $b --> Polynomial) {
      Polynomial.new:
	coefficients => ($a[$_] - $b[$_] for ^max(($a,$b)».degree))
    }
    multi infix:<*>(Polynomial $a, Polynomial $b --> Polynomial) {
      my @coefficients;
      for ^$a.degree -> $i { for ^$b.degree -> $j { @coefficients[$i+$j]+=$a[$i]*$b[$j] } }
      Polynomial.new: :@coefficients;
    }
    multi infix:<divmod>(Polynomial $a, Polynomial $b) {
      %(
	synthetic-division $a.coefficients, $b.coefficients
      )<quotient remainder>.map:
	{ Polynomial.new: coefficients => @$_ }
    }


    constant NUMBER-OF-SYNDROMES = 2;

    sub encode(@coefficients) is export {
      my Polynomial $P .=new: coefficients => (0 xx NUMBER-OF-SYNDROMES, @coefficients).flat;

      [*] ^NUMBER-OF-SYNDROMES .map: { Polynomial.new: coefficients => ($_, -1) }

    }
  }

}

# vi: shiftwidth=2 nu
