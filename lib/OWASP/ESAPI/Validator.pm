package OWASP::ESAPI::Validator;
use Moose;

with qw(
    OWASP::ESAPI::Role::ESAPI
);

use OWASP::ESAPI::ValidationRule;
use OWASP::ESAPI::ValidationRule::HTML;
use DateTime;
use MooseX::Types::CreditCard qw( CreditCard );
use MooseX::Types::Path::Class;
use Scalar::Util qw( blessed );
use Try::Tiny;

has '+esapi' => (
    handles => {
        'encoder' => 'encoder',
    },
);

sub _is_valid {
    my ($self, %params) = @_;

    my $method = delete $params{method};
    return try {
        $self->$method(%params);
        return 1;
    }
    catch {
        return '';
    };
}

sub _get_valid {
    my ($self, %params) = @_;

    my $rule_class = 'OWASP::ESAPI::ValidationRule';
    if ($params{rule}) {
        $rule_class .= "::$params{rule}";
    }

    my $rule = $rule_class->new(
        esapi    => $self->esapi,
        type     => $type,
        optional => $params{optional},
    );

    my %validation_params = (
        context => $params{context},
        input   => $params{input},
    );
    $validation_params{error_list} = $params{error_list}
        if exists $params{error_list};

    return $rule->get_valid(%validation_params);
}

sub is_valid_input {
    my ($self, %params) = validated_hash(\@_,
        method     => { isa => 'Str' },
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        type       => { isa => 'Str' },
        optional   => { isa => 'Bool' },
    );

    return $self->_is_valid(%params, method => 'get_valid_input');
}

sub get_valid_input {
    my ($self, %params) = validated_hash(\@_,
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        type       => { isa => 'Str' },
        optional   => { isa => 'Bool' },
        error_list => { isa => 'ArrayRef' },
    );

    my $type = $self->esapi->security_configuration->get_validation_type(
        type => $params{type},
    );

    return $self->_get_valid(%params, type => $type);
}

sub is_valid_date {
    my ($self, %params) = validated_hash(\@_,
        context       => { isa => 'Str' },
        input         => { isa => 'Str' },
        format        => { isa => 'Object|ClassName' },
        format_method => { isa => 'Str', default => 'parse_datetime' },
        optional      => { isa => 'Bool' },
    );

    return $self->_is_valid(%params, method => 'get_valid_date');
}

sub get_valid_date {
    my ($self, %params) = validated_hash(\@_,
        context       => { isa => 'Str' },
        input         => { isa => 'Str' },
        format        => { isa => 'Object|ClassName' },
        format_method => { isa => 'Str', default => 'parse_datetime' },
        optional      => { isa => 'Bool' },
        error_list    => { isa => 'ArrayRef' },
    );

    # We create type named after the format, which should probably a
    # DateTime::Format::* class, like DateTime::Format::HTTP or
    # DateTime::Format::Natural.
    #
    # This is made a little difficult because there's no real standard
    # interface for the DateTime parsers. There's this sort of informal
    # recommendation that they be named "DateTime::Format::*" and that they
    # should probably provide parse_datetime methods, but some provide
    # parse_date or parse_time methods and who knows if they are all in the
    # correct namespace.

    my $format    = $params{format};
    my $class     = blessed $format // $format;
    my $name      = $format =~ /(\w+)$/;
    my $type_name = "OWASP::ESAPI::Reference::DefaultValidator::DateTime::$name\::$format_method"

    my $type = Moose::Util::TypeConstraints::find_type_constraints($type_name);

    if (!$type) {
        subtype $type_name => as 'DateTime';

        coerce $type_name
            => from 'Str'
            => where { $format->$format_method($_) };
    }
    
    $type = Moose::Util::TypeConstraints::find_type_constraints($type_name);
    
    throw {
        ident   => 'unable to create type constraint',
        tags    => [ 'internal' ],
        message => 'unable to create type constraint %{type_name}s',
        payload => {
            type_name => $type_name,
        },
    } unless $type;

    return $self->_get_valid(%params, type => $type);
}

sub is_valid_safe_html {
    my ($self, %params) = validated_hash(\@_,
        method     => { isa => 'Str' },
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        type       => { isa => 'Str' },
        optional   => { isa => 'Bool' },
    );

    return $self->_is_valid(%params, method => 'get_valid_safe_html');
}

sub get_valid_safe_html {
    my ($self, %params) = validated_hash(\@_,
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        type       => { isa => 'Str' },
        optional   => { isa => 'Bool' },
        error_list => { isa => 'ArrayRef' },
    );

    my $type = $self->esapi->security_configuration->get_validation_type(
        type => $params{type},
    );

    return $self->_get_valid(%params, rule => 'HTML', type => $type);
}

sub is_valid_credit_card {
    my ($self, %params) = validated_hash(\@_,
        method     => { isa => 'Str' },
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        optional   => { isa => 'Bool' },
    );

    return $self->_is_valid(%params, method => 'get_valid_credit_card');
}

sub get_valid_credit_card {
    my ($self, %params) = validated_hash(\@_,
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        optional   => { isa => 'Bool' },
        error_list => { isa => 'ArrayRef' },
    );

    return $self->_get_valid(%params, type => CreditCard);
}

sub is_valid_directory_path {
    my ($self, %params) = validated_hash(\@_,
        method     => { isa => 'Str' },
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        optional   => { isa => 'Bool' },
    );

    return $self->_is_valid(%params, method => 'get_valid_directory_path');
}

sub get_valid_directory_path {
    my ($self, %params) = validated_hash(\@_,
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        optional   => { isa => 'Bool' },
        error_list => { isa => 'ArrayRef' },
    );

    return $self->_get_valid(%params, type => 'Path::Class::Dir');
}

sub is_valid_file_name {
    my ($self, %params) = validated_hash(\@_,
        method     => { isa => 'Str' },
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        optional   => { isa => 'Bool' },
    );

    return $self->_is_valid(%params, method => 'get_valid_file_name');
}

sub get_valid_file_name {
    my ($self, %params) = validated_hash(\@_,
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        optional   => { isa => 'Bool' },
        error_list => { isa => 'ArrayRef' },
    );

    return $self->_get_valid(%params, type => 'Path::Class::File');
}

sub is_valid_number {
    my ($self, %params) = validated_hash(\@_,
        method     => { isa => 'Str' },
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        optional   => { isa => 'Bool' },
    );

    return $self->_is_valid(%params, method => 'get_valid_number');
}

sub is_valid_double { shift->is_valid_number(@_) }

sub get_valid_number {
    my ($self, %params) = validated_hash(\@_,
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        optional   => { isa => 'Bool' },
        error_list => { isa => 'ArrayRef' },
    );

    return $self->_get_valid(%params, type => 'Num');
}

sub get_valid_double { shift->get_valid_number(@_) }

sub is_valid_integer {
    my ($self, %params) = validated_hash(\@_,
        method     => { isa => 'Str' },
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        optional   => { isa => 'Bool' },
    );

    return $self->_is_valid(%params, method => 'get_valid_integer');
}

sub get_valid_integer {
    my ($self, %params) = validated_hash(\@_,
        context    => { isa => 'Str' },
        input      => { isa => 'Maybe[Str]' },
        optional   => { isa => 'Bool' },
        error_list => { isa => 'ArrayRef' },
    );

    return $self->_get_valid(%params, type => 'Int');
}

# TODO Add each of the following methods
#
#    is_valid_file_content
#    get_valid_file_content
#
#    is_valid_file_upload
#    assert_valid_file_upload
#
#    is_valid_list_item
#    get_valid_list_item
#
#    is_valid_http_request_parameter_set
#    assert_valid_http_request_parameter_set
#
#    is_valid_printable
#    get_valid_printable
#
#    is_valid_redirect_location
#    get_valid_redirect_location
#
#    safe_read_line

__PACKAGE__->meta->make_immutable;
