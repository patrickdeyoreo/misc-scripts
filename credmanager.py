#!/usr/bin/env python3
"""
Provides a class 'CredentialManager' to manage account credentials
"""

from argparse import ArgumentParser
import json
from os import access, getenv, R_OK, W_OK, X_OK
from pathlib import Path
import sys
from getpass import getpass
import gpg


def main():
    """Execute the credential manager"""
    args = parse_args()
    credman = CredentialManager(args.filename, gpghome=args.gpghome)
    credman.display()
    credman.save()


def parse_args():
    """Parse command-line arguments"""
    parser = ArgumentParser(
        prog=Path(sys.argv[0]).stem,
        description='Manage login credentials'
    )
    parser.add_argument(
        '--gpghome', type=str,
        default=getenv('GNUPGHOME', str(Path.home().joinpath('.gnupg'))),
        help='GPG directory containing keyrings and a trust DB'
    )
    parser.add_argument(
        'filename', type=str,
        default=str(Path.cwd().joinpath('credentials.gpg')),
        help='file containing encrypted account credentials'
    )
    return parser.parse_args()


def trap(exceptions, handler, *args, **kwargs):
    """Create a decorator to catch an exception"""
    def decorator(fun):
        """Wrap a function in an interrupt handler"""
        def decorated(*__args, **__kwargs):
            """Call a function within an interrupt handler"""
            try:
                return fun(*__args, **__kwargs)
            except tuple(exceptions):  # pylint: disable=catching-non-exception
                return handler(*args, **kwargs)
        return decorated
    return decorator


class CredentialManager:
    """
    Manage encrypted login credentials
    """
    @trap([KeyboardInterrupt], sys.exit, 130)
    def __init__(self, filename=None, gpghome=None):
        """
        Instantiate a credential manager
        """
        if gpghome is None:
            gpghome = getenv('GNUPGHOME', str(Path.home().joinpath('.gnupg')))
        if not Path(gpghome).exists():
            raise FileNotFoundError(f"{gpghome}: No such file or directory")
        if not access(gpghome, R_OK | W_OK | X_OK):
            raise PermissionError(f"{gpghome}: Permission denied")
        self.__accounts = {}
        self.__filename = filename
        self.__encoder = json.JSONEncoder()
        self.__decoder = json.JSONDecoder()
        self.__gpg = gpg.Context(armor=True, home_dir=gpghome)
        self.load()

    @property
    def filename(self):
        """
        Get the value of the private attribute 'filename'
        """
        return self.__filename

    @filename.setter
    def filename(self, filename):
        """
        Get the value of the private attribute 'filename'
        """
        if filename is None:
            filename = Path.cwd().joinpath('credentials.gpg')
        if isinstance(filename, Path):
            filename = str(filename)
        if isinstance(filename, str):
            self.__filename = filename
        else:
            raise TypeError("filename must be of type 'Path' or 'str'")

    def add(self, account, **creds):
        """
        Add account credentials
        """
        if account in self.__accounts:
            print(f"* [ERROR] {account}: Already exists", file=sys.stderr)
        else:
            self.__accounts[account] = {'user': None, 'pass': None, **creds}

    def remove(self, account):
        """
        Remove account credentials
        """
        if account in self.__accounts:
            del self.__accounts[account]
        else:
            print(f"* [ERROR] {account}: No such account", file=sys.stderr)

    def update(self, account, **credentials):
        """
        Update account credentials
        """
        self.__accounts[account].update(credentials)

    def display(self, account=None):
        """
        Display account credentials
        """
        if account is None:
            for acct in self.__accounts:
                print(f"> {acct}:")
                for name, creds in self.__accounts[acct].items():
                    print(f"\t* {name}: {creds}")
        elif account in self.__accounts:
            for name, creds in self.__accounts[account].items():
                print(f"* {name}: {creds}")
        else:
            print(f"* [ERROR] {account}: No such account", file=sys.stderr)

    @trap([KeyboardInterrupt], sys.exit, 130)
    def load(self):
        """
        Load, decrypt, and decode account credentials
        """
        try:
            with open(self.filename, 'rb') as ciphertext:
                self.__accounts = self.__decoder.decode(self.__gpg.decrypt(
                    ciphertext,
                    verify=False,
                    passphrase=getpass("Password: ")
                )[0].decode())
            print("Credentials loaded.", file=sys.stderr)
        except FileNotFoundError:
            pass

    @trap([KeyboardInterrupt], sys.exit, 130)
    def save(self):
        """
        Encode, encrypt, and save account credentials
        """
        with open(self.filename, 'w') as ciphertext:
            ciphertext.write(self.__gpg.encrypt(
                self.__encoder.encode(self.__accounts).encode(),
                sign=False,
                passphrase=getpass("Password: "),
            )[0].decode())
        print("Credentials saved.", file=sys.stderr)


if __name__ == "__main__":
    sys.exit(main())


# vi:et:sts=4:sw=4:ts=8
