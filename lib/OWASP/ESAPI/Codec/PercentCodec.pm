package OWASP::ESAPI::Codec::PercentCodec;
use Moose;

extends 'OWASP::ESAPI::Codec';

use Encode ();
use MooseX::Params::Validate;

sub encode_character {
    my ($self, $immune, $c) = validated_list(\@_,
        immune => { isa => 'ArrayRef[Str]' },
        input  => { isa => 'Str' },
    );

    return $c if $c =~ /[a-zA-Z0-9]/;

    # Convert the char to bytes and convert each byte to %FF (or whatever)
    return join '', map { sprintf '%%%02x', ord($_) }  
          split //, Encode::encode('utf8', $c);
}

sub decode_character {
    my ($self, $input) = validated_list(\@_,
        input  => { isa => 'ScalarRef[Str]' },
    );

    if ($$input =~ s/^%([a-fA-F0-9]{2})//) {
        
        # Unlike the Java version we do not attempt to validate that this is a
        # valid code point. Why validate something that will always be a valid
        # code point as all values in the range of 0x00..0xFF are?
        #
        # Do I totally misunderstand something about Unicode here? If I do,
        # the easiest way to fix is probably:
        #
        # use warnings 'FATAL'; # since bad Unicode causes warnings

        return chr(hex($1));
    }

    return substr $$input, 0, 1, '';
}

__PACKAGE__->meta->make_immutable;
