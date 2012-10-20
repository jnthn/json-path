class JSON::Path {
    has $!path;

    my enum ResultType < ValueResult PathResult >;

    multi method new($path) {
        self.bless(*, :$path);
    }

    submethod BUILD(:$!path as Str) { }

    multi method Str(JSON::Path:D:) {
        $!path
    }

    method !get($object, ResultType $rt) {
        die "NYI";
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
