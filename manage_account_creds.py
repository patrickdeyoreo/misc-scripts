#! /usr/bin/env python3

## Manage an encrypted file of account credentials


import argparse
import getpass
import gnupg
import json

from os  import getenv, path
from sys import argv




## Class to manage reading and updating the accounts file
class CredManager(object):

  # Initializes a CredManager object
  def __init__(self, filename=path.join(getenv('PWD', str()), 'credentials'),
      gnupghome=getenv('GNUPGHOME', path.join(getenv('HOME', str()), '.gnupg'))
  ):
    # Dictionary to hold account credentials
    self.__accounts = dict()
    # Name of the account credentials file
    self.__filename = filename
    # GPG object to encrypt & decrypt data
    self.__gpg      = gnupg.GPG(gnupghome=gnupghome)
    # JSON coders to serialize account data]
    self.__encoder  = json.JSONEncoder()
    self.__decoder  = json.JSONDecoder()
    # Load credentials from file
    self.load()


  # Adds a new account
  def add(self, acct, **creds):
    self.__accounts.setdefault(acct, { 'user': None, 'pass': None, **creds })
    return self


  # Updates credentials for an existing account
  def update(self, acct, **creds):
    if self.__accounts.get(acct, None) == None:
      print("{}: no account named '{}'\n".format(type(self).__name__, acct))
    else:
      self.__accounts[acct].update(creds)
    return self


  # Removes an existing account
  def remove(self, acct):
    if self.__accounts.pop(acct, None) == None:
      print("{}: no account named '{}'\n".format(type(self).__name__, acct))
    return self


  # Prints credentials for an existing account
  def display(self, acct):
    if self.__accounts.get(acct, None) == None:
      print("{}: no account named '{}'\n".format(type(self).__name__, acct))
    else:
      for cred in self.__accounts[acct].keys():
        print("{}: {}\n".format(cred, self.__accounts[acct][cred]))
    return self


  # Prints credentials for an existing account
  def display_all(self):
    for acct in self.__accounts.keys():
      print("# {}".format(acct))
      for cred in self.__accounts[acct].keys():
        print("{}: {}".format(cred, self.__accounts[acct][cred]))
    return self


  # Reads, decrypts, and decodes data from the credentials file
  def load(self):
    with open(self.__filename, 'r') as istream:
      self.__accounts = self.__decoder.decode(str(
          self.__gpg.decrypt(
            istream.read(),
            passphrase=getpass.getpass("Password: ")
        )))
    return self


  # Encodes, encrypts, and writes data to the credentials file
  def save(self):
    with open(self.__filename, 'w') as ostream:
      ostream.write(str(
        self.__gpg.encrypt(
          self.__encoder.encode(self.__accounts),
          None,
          symmetric=True,
          passphrase=getpass.getpass("Password: ")
      )))
    return self




## Run the script unless it's being imported as a module
if __name__ == "__main__":

  # Set up an argument parser to handle command-line args
  parser = argparse.ArgumentParser(
      prog=argv[0].split('/')[-1],
      description='Manage an encrypted file of account credentials.'
  )

  # Require the name of the credentials file as an argument
  parser.add_argument(
      'filename', type=str,
      default=path.join(getenv('PWD', str()), 'credentials'),
      help='Name of the credentials file.'
  )

  # Allow gnupghome to be specified as an argument
  parser.add_argument(
      '--gnupghome', type=str,
      default=path.join(getenv('HOME', str()), '.gnupg'),
      help='GNUPG directory for keyring files and a trust database.'
  )

  # Parse command-line arguments
  args = parser.parse_args()

  # Instantiate a credentials manager
  credmanager = CredManager(filename=args.filename, gnupghome=args.gnupghome)

  # Display all account credentials
  credmanager.display_all()

  # Write account credentials to file
  credmanager.save()



# vim:et:sts=2:sw=2:ts=8:tw=80
