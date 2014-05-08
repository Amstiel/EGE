# Copyright © 2014 Darya D. Gornak 
# Licensed under GPL version 2 or later.
# http://github.com/dahin/EGE
package EGE::SQL::Table;

use strict;
use warnings;

sub new {
    my ($class, $fields) = @_;
    $fields or die;
    my $self = {
        fields => $fields,
        data => [],
        field_index => {},
    };
    my $i = 0;
    $self->{field_index}->{$_} = $i++ for @$fields;
    bless $self, $class;
    $self;
}

sub insert_row {
    my $self = shift;
    @_ == @{$self->{fields}}
        or die sprintf "Wrong column count %d != %d", scalar @_, scalar @{$self->{fields}};
    push @{$self->{data}}, \@_;
    $self;
}

sub insert_rows {
    my $self = shift;
    $self->insert_row(@$_) for @_;
    $self;
}

sub print_row { print join("\t", @{$_[0]}), "\n"; }

sub print {
    my $self = shift;
    print_row $_ for $self->{fields}, @{$self->{data}};
}
sub count {
    @{$_[0]->{data}};
}

sub select {
    my ($self, $fields, $where) = @_;
    my $tab_where = $self->where($where);
    my $result = EGE::SQL::Table->new($fields);
    my @indexes = map $tab_where->{field_index}->{$_} // die("Unknown field $_"), @$fields;
    $result->{data} = [ map [ @$_[@indexes] ], @{$tab_where->{data}} ];
    $result;
}


sub where {
    my ($self, $where) = @_;
    $where or return $self;
    my $table = EGE::SQL::Table->new($self->{fields});
    for my $data (@{$self->{data}}) {
        my $hash = {};
        $hash->{$_} = @$data[$self->{field_index}->{$_}] for @{$self->{fields}};
        push @{$table->{data}}, [@$data] if $where->run($hash);
    }
    $table;
}

sub update {
    my ($self, $fields, $func) = @_;
    my @indexes = map $self->{field_index}->{$_} // die("Unknown field $_"), @$fields;
    @$_[@indexes] = $func->(@$_[@indexes]) for (@{$self->{data}}); 
}

1;
