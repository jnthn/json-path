class JSON::Path {
    has $!path;

    my enum ResultType < ValueResult PathResult >;

    my grammar JSONPathGrammar {
        token TOP {
            ^
            <.command>+
            [ $ || <giveup> ]
        }
        
        proto token command    { * }
        token command:sym<$>   { <sym> }
        token command:sym<.>   { <sym> <ident> }
        token command:sym<[n]> { '[' ~ ']' $<n>=[\d+] }
        
        method giveup() {
            die "Parse error near pos " ~ self.pos;
        }
    }
    
    multi method new($path) {
        self.bless(*, :$path);
    }

    submethod BUILD(:$!path as Str) { }

    multi method Str(JSON::Path:D:) {
        $!path
    }

    method !get($object, ResultType $rt) {
        my $current = $object;
        gather {
            JSONPathGrammar.parse($!path, actions => class {
                method command:sym<$>($/) {
                    $current = $object;
                }
                
                method command:sym<.>($/) {
                    $current = $current{~$<ident>};
                }
                
                method command:sym<[n]>($/) {
                    $current = $current[+$<n>];
                }
            });
            take $current;
        }
    }

    method paths($object) {
        self!get($object, PathResult);
    }

    method values($object) {
        self!get($object, ValueResult);
    }

    method value($object) is rw {
        self.values.[0]
    }
}

sub jpath($object, $expression) is export {
	JSON::Path.new($expression).values($object);
}

sub jpath1($object, $expression) is rw is export {
	JSON::Path.new($expression).value($object);
}

sub jpath_map(&coderef, $object, $expression) {
	JSON::Path.new($expression).map($object, &coderef);
}
