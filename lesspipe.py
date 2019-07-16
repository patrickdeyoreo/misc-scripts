#!/usr/bin/env python3
#
# lessfile / lesspipe
# Input pre/post-processor to help `less' handle non-text input
#
# Usage: eval "$(lessfile)"
#    or: eval "$(lesspipe)"
#
# Writing lessfile & lesspipe as one file to avoid duplication of decode stage
# shell could sure be icky, so I'm doing it in Python
#
# Unfortunately, if you want to name `lessfile', `lesspipe', or `lessfilter'
# something else, you'll need to configure the relevant environment variable,
# which will be either LESSFILE_NAME, LESSPIPE_NAME or LESSFILTER_NAME
#
# LESSOPEN:
#    argv[1] : name of file to preprocess
#
# LESSCLOSE::
#    argv[1] : name of the original file
#    argv[2] : name of the file created by LESSOPEN


import os
import subprocess
import sys
import tempfile


## Definition of a less input processor to handle pre/post-processing
class InputProcessor(object):

    ## Initialize preprocessor attributes
    def __init__(self, path):

        self.abspath  = os.path.abspath(path)
        self.basename = os.path.basename(self.abspath)
        self.outfd    = sys.stdout.fileno()
        self.names = {
            'lessfile'   : os.getenv('LESSFILE_NAME', 'lessfile'),
            'lesspipe'   : os.getenv('LESSPIPE_NAME', 'lesspipe'),
            'lessfilter' : os.getenv('LESSFILTER_NAME', '.lessfilter'),
        }


    ## Output commands that will configure the shell to use lesspipe
    def less_setup(self):

        if os.path.basename(os.getenv('SHELL', 'sh')).endswith('csh'):
            lessopen  = 'setenv LESSOPEN "{}";'
            lessclose = 'setenv LESSCLOSE "{}";'
        else:
            lessopen  = 'export LESSOPEN="{}";'
            lessclose = 'export LESSCLOSE="{}";'

        if self.basename == self.names['lessfile']:
            print(lessopen.format('| {} %s'.format(self.abspath)))
            print(lessclose.format('{} %s %s'.format(self.abspath)))
        else:
            print(lessopen.format('||- {} %s'.format(self.abspath)))
            print(lessclose.format('{} %s %s'.format(self.abspath)))

        return True


    ## Process the input file and direct output appropriately
    def lessopen(self, infile):

        if self.basename == self.names['lessfile']:
            os.umask(0o077)
            self.outfd, outfile = tempfile.mkstemp(prefix='less-')
        try:
            lessfilter = subprocess.run([
                os.path.join(os.getenv('HOME'), self.names['lessfilter']),
                infile
            ], stdout=self.outfd)
        except FileNotFoundError:
            pass
        else:
            if lessfilter.returncode == 0:
                if self.basename == self.names['lessfile']:
                    os.close(self.outfd)
                    if os.stat(outfile).st_size > 0:
                        print(outfile)
                    else:
                        os.remove(outfile)
                return True
        try:
            with open(infile, 'rb') as fin:
                os.write(self.outfd, fin.read())
        except FileNotFoundError:
            if infile == '-':
                with os.fdopen(os.sys.stdin.fileno(), 'rb') as fin:
                    os.write(self.outfd, fin.read())
        finally:
            if self.basename == self.names['lessfile']:
                os.close(self.outfd)
                if os.stat(outfile).st_size > 0:
                    print(outfile)
                else:
                    os.remove(outfile)
        return True



    ## Remove the file we created if we were called as lessfile
    def lessclose(self, infile, tmpfile):

        if self.basename == self.names['lessfile']:
            try:
                os.remove(os.path.realpath(tmpfile))
            except FileNotFoundError:
                pass
            except:
                os.stderr.write(
                    '{}: failed to remove temp file: {}\n'.format(
                        self.basename, sys.exc_info()[0]))
                raise
            return True



    ## Execute an action based on the number of arguments received
    def run(self, *args):

        if   len(args) == 0:
            return self.less_setup()
        elif len(args) == 1:
            return self.lessopen(*args)
        elif len(args) == 2:
            return self.lessclose(*args)
        else:
            raise ValueError(
                '{}: expected no more than 2 arguments (got {})'.format(
                    self.name, len(args)))



## Run start the input processor
if __name__ == '__main__':
    if InputProcessor(__file__).run(*sys.argv[1:]):
        sys.exit(0)
    else:
        sys.exit(1)



# vi:ft=python:et:sts=4:sw=4
