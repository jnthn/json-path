class JSON::Path {
    has $!path;
    
    multi method new($path) {
        self.bless(*, :$path);
    }
    
    submethod BUILD(:$!path as Str) { }
    
    multi method Str(JSON::Path:D:) {
        $!path
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
