#!/usr/bin/env python3
"""
Find duplicate files
"""

from argparse import Action, ArgumentParser
from hashlib import md5
from os import listdir, path
from shlex import quote
import sys


def listfiles(paths, recursive=False):
    """
    Expand a list of files from a list of names
    """
    files = list()
    for name in paths:
        if path.isdir(name):
            if recursive:
                files.extend(name.recurse(name))
            else:
                files.extend((path.join(name, file) for file in listdir(name)))
        else:
            files.append(name)
    files.sort()
    return files


def genfilelist(name):
    """
    Extend files with the contents of directory and its subdirectories
    """
    if path.isdir(name):
        return (path.join(name, file) for item in listdir(name)
                for file in genfilelist(path.join(name, item)))
    return [name]


def parseargs():
    """
    Parse arguments
    """
    parser = ArgumentParser(prog=path.basename(sys.argv[0]))

    parser.add_argument("-r", "--recursive",
                        action="store_true",
                        help="operate recursively on directories")
    parser.add_argument("-v", "--verbose",
                        action="store_true",
                        help="print the name of each file as it's checked")
    parser.add_argument("files",
                        nargs="+",
                        action="extend",
                        help="files and directories to check for duplicates")
    return parser.parse_args()


def main():
    """
    Execute program
    """
    args = parseargs()
    checksums = dict()
    duplicates = set()
    exitstatus = 0
    for file in listfiles(set(args.files)):
        md5sum = md5()
        try:
            with open(file, "rb") as istream:
                md5sum.update(istream.read())
        except FileNotFoundError:
            print(f"File not found: {quote(file)}", file=sys.stderr)
            exitstatus = 1
        else:
            if getattr(args, "verbose") is True:
                print(f"{md5sum.hexdigest()}: {quote(file)}")
            if md5sum.digest() in checksums:
                duplicates.add(md5sum.digest())
                checksums[md5sum.digest()].append(file)
            else:
                checksums[md5sum.digest()] = [file]
    for digest in duplicates:
        print(f"-- {digest.hex()} --")
        print(*map(quote, checksums[digest]), sep="\n")
    return exitstatus


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
