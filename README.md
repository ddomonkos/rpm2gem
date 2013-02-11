# rpm2gem

Rpm2gem is a script allowing conversion of RubyGems libraries from the RPM format back to RubyGems (gem). While the result should be just as functional as its RPM counterpart, it may lack some metadata. This metadata is either not present in the RPM at all (but, say, older versions of the same library in RubyGems format have this metadata) or the script did not succeed to extract it from the RPM specfile.

The only time the script might fail to produce a properly working result is when the library uses C extensions. In such case it attempts to extract its source files from source RPM (SRPM) if provided, however this can fail. Unfortunately, rpm2gem is unable to detect such occurence and thus human oversight is recommended.

This script was created for the needs of the [Tool for RubyGems -- RPM synchronization](http://is.muni.cz/th/373796/fi_b/thesis.pdf "Thesis") project.

## USAGE:

Even though the script was created to be used by a web service application, it can be used as stand-alone as well. All necessary information should be available in the script's help output.
