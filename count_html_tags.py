#!/usr/bin/env python3
"""
Count closed HTML tags
"""
import argparse
import html.parser
import os
import re
import sys


class HTMLTagCounter(html.parser.HTMLParser):
    """
    Parse HTML and count the resulting tags
    """
    def __init__(self, *args, **kwargs):
        """
        Initialize a new parser instance
        """
        super().__init__(*args, **kwargs)
        self.n_tags = 0

    def handle_endtag(self, tag):
        """
        Increment tag count upon encountering a closing tag
        """
        self.n_tags += 1

    def reset(self):
        """
        Reset tag count to zero
        """
        super().reset()
        self.n_tags = 0


def main():
    """
    Parse arguments, read input and count HTML tags
    """
    parser = argparse.ArgumentParser(prog=os.path.basename(sys.argv[0]))
    parser.add_argument('files', nargs='*', default='-')
    args = parser.parse_args()
    counter = HTMLTagCounter()
    exitval = 0
    maxtags = 0
    results = {}
    for arg in args.files or '-':
        try:
            if arg == '-':
                counter.feed(sys.stdin.read())
            else:
                with open(arg, 'r') as istream:
                    counter.feed(istream.read())
        except (FileNotFoundError, IsADirectoryError, PermissionError) as exc:
            print(': '.join((sys.argv[0], arg, exc.strerror)), file=sys.stderr)
            results[arg] = 0
            exitval = 1
        else:
            maxtags = max((counter.n_tags, maxtags))
            results[arg] = counter.n_tags
            counter.reset()
    if len(results) > 1:
        numsfmt = '{{:{}d}}'.format(len(str(maxtags)))
        for arg in args.files:
            print(numsfmt.format(results[arg]), arg)
    else:
        print(maxtags)
    return exitval


if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
