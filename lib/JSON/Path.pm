class JSON::Path {
    has $!path;

    my enum ResultType < ValueResult PathResult >;

    my grammar JSONPathGrammar {
        token TOP {
            ^
            <commandtree>
            [ $ || <giveup> ]
        }
        
        token commandtree {
            <command> <commandtree>?
        }
        
        proto token command    { * }
        token command:sym<$>   { <sym> }
        token command:sym<.>   { <sym> <ident> }
        token command:sym<[n]> {
            | '[' ~ ']' $<n>=[\d+]
            | "['" ~ "']" $<n>=[\d+]
        }
        token command:sym<['']> {
            "['" ~ "']" $<key>=[<-[']>+]
        }
        
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
        my @path;
        my &collector = JSONPathGrammar.parse($!path,
            actions => class {
                method TOP($/) {
                    make $<commandtree>.ast;
                }
                
                method commandtree($/) {
                    make $<command>.ast.assuming(
                        $<commandtree>
                            ?? $<commandtree>[0].ast
                            !! -> $result { 
                                take do given $rt {
                                    when ValueResult { $result }
                                    when PathResult  { @path.join('') }
                                }
                            });
                }
                
                method command:sym<$>($/) {
                    make sub ($next, $current) {
                        @path.push('$');
                        $next($object);
                    }
                }
                
                method command:sym<.>($/) {
                    my $key = ~$<ident>;
                    make sub ($next, $current) {
                        @path.push("['$key']");
                        $next($current{$key});
                    }
                }
                
                method command:sym<[n]>($/) {
                    my $idx = +$<n>;
                    make sub ($next, $current) {
                        @path.push("['$idx']");
                        $next($current[$idx]);
                    }
                }
                
                method command:sym<['']>($/) {
                    my $key = ~$<key>;
                    make sub ($next, $current) {
                        @path.push("['$key']");
                        $next($current{$key});
                    }
                }
            }).ast;
        gather &collector($object);
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
