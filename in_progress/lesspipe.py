#!/usr/bin/env python3
#
# lesspipe / lessfile
# A filter for less handle non-text files.
#
# Usage: eval "$(lesspipe)" or eval "$(lessfile)"
#
# Writing lessfile & lesspipe as one file to avoid duplication of decode stage
# shell could sure be icky (so I'm writing it in Python). Unfortunately, I'll
# still have filename dependencies sprinkled throughout the code.
#
# If you want to name lesspipe / lessfile something else, you can change
# the 'lesspipe_basename' / 'lessfile_basename' variables below
#
# less passes in:
#    argv[1] : filename to be viewed with less  (used by LESSOPEN)
# and, if used by lessfile:
#    argv[2] : filename created during while executing LESSOPEN



## Import required modules
import os
import sys
import subprocess
import tempfile


## Define lesspipe / lessfile basenames
lesspipe_basename = 'lesspipe'
lessfile_basename = 'lessfile'
lessfilter_basename = '.lessfilter'


## Definition of a less input processor to handle pre/post-processing
class InputProcessor(object):

    ## Initialize preprocessor attributes
    def __init__(self, basename=None):
        self.basename = basename if basename else os.path.basename(sys.argv[0])
        self.out = sys.stdout.fileno()


    ## Output commands that will configure the shell to use lesspipe
    def lesspipe_setup(self):
        script = os.path.realpath(__file__)
        shell  = os.path.basename(os.getenv('SHELL', 'sh'))
        if  shell == 'csh':
            print('setenv LESSOPEN "| {} %s";'.format(script))
            print('setenv LESSCLOSE "{} %s %s";'.format(script))
        else:
            print('export LESSOPEN="| {} %s";'.format(script))
            print('export LESSCLOSE="{} %s %s";'.format(script))


    ## Process the input file and direct output appropriately
    def lessopen(self, file_in):
        if self.basename == lessfile_basename:
            os.umask(0o077)
            self.out, file_tmp = tempfile.mkstemp(prefix='less-')
        try:
            ps = subprocess.run(
                    [os.path.join(os.environ['HOME'], '.lessfilter'), file_in],
                    stdout=self.out
                )
        except (FileNotFoundError, KeyError):
            pass
        else:
            if ps.returncode == 0:
                if self.basename == lessfile_basename:
                    os.close(self.out)
                    if os.stat(file_tmp).st_size > 0:
                        print(file_tmp)
                    else:
                        os.remove(file_tmp)
                return True

        ## Run filter here

        if self.basename == lessfile_basename:
            os.close(self.out)
            if os.stat(file_tmp).st_size > 0:
                print(file_tmp)
            else:
                os.remove(file_tmp)
        return True


    ## Remove the file we created if we were called as lessfile
    def lessclose(self, file_in, file_tmp):
        try:
            os.remove(file_tmp)
        except:
            os.stderr.write(
                    '{}: failed to delete temporary file: {}\n'.format(
                    self.name, sys.exc_info()[0]
                ))
            raise
        return True


    ## Execute an action based on the number of arguments received
    def run(self, *args):

        if   len(args) == 0:
            return self.lesspipe_setup()

        elif len(args) == 1:
            return self.lessopen(*args)

        elif len(args) == 2:
            return self.lessclose(*args)

        else:
            raise ValueError(
                '{}: expects no more than 2 arguments (got {})'.format(
                    self.name, len(args)
            ))



## Run start the input processor
if __name__ == '__main__':

    input_processor = InputProcessor(basename=os.path.basename(sys.argv[0]))
    if input_processor.run(*sys.argv[1:]) == True:
        exit(0)
    else:
        exit(1)



# vi:ft=python:et:sts=4:sw=4:ts=8
