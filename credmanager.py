#!/usr/bin/env python3
"""
Provides a class 'CredentialManager' to manage account credentials
"""

import argparse
import gpg
import json
import os
import sys
from getpass import getpass


def trap(exceptions, trap, *args, **kwargs):
    """Create a decorator to catch an exception"""
    def decorator(fn):
        """Wrap a function in an interrupt handler"""
        def decorated(*fargs, **fkwargs):
            """Call a function within an interrupt handler"""
            try:
                return fn(*fargs, **fkwargs)
            except tuple(exceptions) as exc:
                if callable(trap):
                    return trap(*args, **kwargs)
                return exc
        return decorated
    return decorator


class CredentialManager(object):
    """
    Manage an encrypted file of credentials
    """
    @trap([KeyboardInterrupt], sys.exit, 130)
    def __init__(self, filename=None, gpghome=None):
        """
        Instantiate a credential manager
        """
        if gpghome is None:
            gpghome = os.getenv(
                'GNUPGHOME',
                os.path.join(os.getenv('HOME'), '.gnupg')
            )
        if not os.path.exists(gpghome):
            raise FileNotFoundError(f"{gpghome}: No such file or directory")
        if not os.access(gpghome, os.R_OK | os.W_OK | os.X_OK):
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
            self.__filename = os.path.join(os.getcwd(), 'credentials.gpg')
        elif type(filename) is str:
            self.__filename = filename
        else:
            raise TypeError("filename must be of type 'str'")

    def add(self, account, **credentials):
        """
        Add account credentials
        """
        self.__accounts.setdefault(
            account, {'user': None, 'pass': None, **credentials}
        )

    def remove(self, account):
        """
        Remove account credentials
        """
        if account in self.__accounts:
            del self.__accounts[account]
        else:
            print(f"{self.__name__}: {account}: No such account",
                  file=sys.stderr)

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
            for account in self.__accounts:
                print(f"{account}:")
                for name, value in self.__accounts[account].items():
                    print(f"{name}: {value}")

        elif account in self.__accounts:
            for name, value in self.__accounts[account].items():
                print(f"{name}: {value}")

        else:
            print(f"{self.__name__}: {account}: No such account",
                  file=sys.stderr)

    @trap([KeyboardInterrupt], sys.exit, 130)
    def load(self):
        """
        Load, decrypt, and decode account credentials
        """
        try:
            with open(self.filename, 'rb') as ciphertext:
                self.__accounts = self.__decoder.decode(
                    self.__gpg.decrypt(
                        ciphertext,
                        verify=False,
                        passphrase=getpass("Password: "),
                    )[0].decode()
                )
            print("Credentials loaded.", file=sys.stderr)
        except FileNotFoundError:
            pass

    @trap([KeyboardInterrupt], sys.exit, 130)
    def save(self):
        """
        Encode, encrypt, and save account credentials
        """
        with open(self.filename, 'w') as ciphertext:
            ciphertext.write(
                self.__gpg.encrypt(
                    self.__encoder.encode(self.__accounts).encode(),
                    sign=False,
                    passphrase=getpass("Password: "),
                )[0].decode()
            )
        print("Credentials saved.", file=sys.stderr)


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        prog=os.path.basename(sys.argv[0]),
        description='Manage sensitive account credentials'
    )
    parser.add_argument(
        'filename',
        type=str,
        help='name of file containing encrypted account credentials',
        default=os.path.join(os.getcwd(), 'credentials.gpg')
    )
    parser.add_argument(
        '--gpghome',
        type=str,
        help='gpg directory containing keyrings and a trust database',
        default=os.getenv(
            'GNUPGHOME',
            os.path.join(os.getenv('HOME'), '.gnupg')
        )
    )
    args = parser.parse_args()
    credman = CredentialManager(args.filename, gpghome=args.gpghome)
    credman.display()
    credman.update('foo.com',
        **{'bar': '{:09d}'.format(__import__('random').randint(0,1000000000))}
    )
    credman.display()
    credman.save()
    sys.exit(0)


# vi:et:sts=4:sw=4:ts=8
