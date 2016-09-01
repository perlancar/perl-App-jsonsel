package App::jsonsel;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use App::CSelUtils;
use Scalar::Util qw(refaddr);

our %SPEC;

sub _encode_json {
    state $json = do {
        require JSON::MaybeXS;
        JSON::MaybeXS->new(allow_nonref=>1, canonical=>1);
    };
    $json->encode($_[0]);
}

sub _decode_json {
    state $json = do {
        require JSON::MaybeXS;
        JSON::MaybeXS->new(allow_nonref=>1, canonical=>1);
    };
    $json->decode($_[0]);
}

$SPEC{jsonsel} = {
    v => 1.1,
    summary => 'Select JSON elements using CSel (CSS-selector-like) syntax',
    args => {
        %App::CSelUtils::foosel_common_args,
        %App::CSelUtils::foosel_struct_action_args,
    },
};
sub jsonsel {
    require JSON::MaybeXS;

    my %args = @_;

    my $expr = $args{expr};
    my $actions = $args{actions};

    # parse first so we can bail early on error without having to read the input
    require Data::CSel;
    Data::CSel::parse_csel($expr)
          or return [400, "Invalid CSel expression '$expr'"];

    my $data;
    if ($args{file} eq '-') {
        binmode STDIN, ":utf8";
        $data = _decode_json(join "", <>);
    } else {
        require File::Slurper;
        $data = _decode_json(File::Slurper::read_text($args{file}));
    }

    require Data::CSel::WrapStruct;
    my $tree = Data::CSel::WrapStruct::wrap_struct($data);

    my @matches = Data::CSel::csel(
        {class_prefixes=>['Data::CSel::WrapStruct']}, $expr, $tree);

    # skip root node itself to avoid duplication
    @matches = grep { refaddr($_) ne refaddr($tree) } @matches
        unless @matches <= 1;

    for my $action (@$actions) {
        if ($action eq 'print') {
            $action = 'print_func_or_meth:meth:value.func:App::jsonsel::_encode_json',
        }
    }

    App::CSelUtils::do_actions_on_nodes(
        nodes   => \@matches,
        actions => $args{actions},
    );
}

1;
#ABSTRACT:

=head1 SYNOPSIS
