package App::jsonsel;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use App::CSelUtils;

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
        %App::CSelUtils::foosel_args_common,
    },
};
sub jsonsel {
    require JSON::MaybeXS;

    App::CSelUtils::foosel(
        @_,

        code_read_tree => sub {
            my $args = shift;
            my $data;
            if ($args->{file} eq '-') {
                binmode STDIN, ":encoding(utf8)";
                $data = _decode_json(join "", <>);
            } else {
                require File::Slurper;
                $data = _decode_json(File::Slurper::read_text($args->{file}));
            }

            require Data::CSel::WrapStruct;
            my $tree = Data::CSel::WrapStruct::wrap_struct($data);
            $tree;
        },

        csel_opts => {class_prefixes=>['Data::CSel::WrapStruct']},

        code_transform_node_actions => sub {
            my $args = shift;

            for my $action (@{ $args->{node_actions} }) {
                if ($action eq 'print' || $action eq 'print_as_string') {
                    $action = 'print_func_or_meth:meth:value.func:App::jsonsel::_encode_json';
                } elsif ($action eq 'dump') {
                    $action = 'dump:value';
                }
            }
        },
    );
}

1;
#ABSTRACT:

=head1 SYNOPSIS
