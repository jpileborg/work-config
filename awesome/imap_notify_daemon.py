#!/usr/bin/env /usr/bin/python
# -*- coding: utf-8 -*-
#######################################################################
# File: imap-notify-daemon.py                                         #
#                                                                     #
# Copyright (C) 2011 by Joachim Pileborg <arrow@pileborg.org>         #
#                                                                     #
# This file may be modified and/or redistributed (in source form only)#
# on condition that the above copyright notice is kept intact.        #
#######################################################################

"""
The purpose of this application is to run in the background, checking
IMAP mail accounts, and displaying a notification icon when new mail
has arrived. It is supposed to be started in the users .xsession file.

This application checks for new mail in all subscribed folders on all
configured accounts.
"""

# TODO
# ====
# o Authentication, other than plaintext password

#######################################################################

# The list of accounts is a Python tuple, containing dictionaries with
# the settings used to log into the account. Format is as follows:
#
# accounts = (
#     { 'name'    : 'First mail server',
#       'server'  : 'imap.domain.name',
#       'username': 'username',
#       'password': 'password'
#       },
#     { 'name'    : 'Another mail server',
#       'server'  : 'imap.other.domain.name',
#       'port'    : 993,
#       'ssl'     : True,
#       'username': 'username',
#       'password': 'password',
#       }
#     )

#######################################################################

import imaplib
import re

#######################################################################

class Mailbox(object):
    name   = ''     # Name of mailbox
    total  = 0      # Total number of mails in mailbox
    unread = 0      # Number of unread messages in mailbox
    new    = False  # Do the mailbox have new mails?

    def __init__(self, name):
        self.name = name

    def check(self, imap):
        _, status = imap.status(self.name, '(MESSAGES UNSEEN)')

        m = re.search(r"MESSAGES (?P<total>\d+) UNSEEN (?P<unread>\d+)", status[0])
        self.total  = int(m.group('total'))
        self.unread = int(m.group('unread'))

        if self.unread > 0:
            self.new = True
        else:
            self.new = False

    def __repr__(self):
        return '%s: %d/%d %s' % (self.name, self.unread, self.total, self.new and '*' or '')

class Server(object):
    name      = ''     # Name of server
    imap      = None   # IMAP connection
    mailboxes = []     # List of all subscribe mailboxes
    total     = 0      # Total number of mails on server
    unread    = 0      # Number of unread messages on server
    new       = False  # If there is new mail on the server

    def __init__(self, name, imap):
        self.name = name
        self.imap = imap

    def get_mailboxes(self):
        _, mailboxes = self.imap.lsub()
        for mb in mailboxes:
            m = re.search(r'^\(.*\) ".+" (?P<mailbox>[\w/]+)$', mb)
            self.mailboxes.append(Mailbox(m.group("mailbox")))

    def check(self):
        total  = 0
        unread = 0
        new    = False

        for mailbox in self.mailboxes:
            mailbox.check(self.imap)
            total  += mailbox.total
            unread += mailbox.unread
            new     = new or mailbox.new

        self.total  = total
        self.unread = unread
        self.new    = new

class Notifier(object):
    servers       = []   # List of all servers to check
    notifications = {}   # Dictionary of all servers with new mail

    def __init__(self):
        self.create_servers()
        self.get_mailboxes()

    def create_servers(self):
        from imap_notify_accounts import accounts as imap_accounts
        import socket

        for account in imap_accounts:
            name = account.get('name', account['server'])

            if account.get('ssl', False):
                port = account.get('port', imaplib.IMAP4_PORT)
                # print('%s: Creating imap connection to %s:%d' % (name, account['server'], port))
                server = imaplib.IMAP4(host = account['server'], port = port)
            else:
                port = account.get('port', imaplib.IMAP4_SSL_PORT)
                # print('%s: Creating SSL imap connection to %s:%d' % (name, account['server'], port))
                server = imaplib.IMAP4_SSL(host = account['server'], port = port)

            if 'username' in account:
                server.login(account['username'], account.get('password', ''))

            self.servers.append(
                Server(name = name, imap = server))

    def get_mailboxes(self):
        for server in self.servers:
            server.get_mailboxes();

    def check(self, server):
        prev_unread = server.unread
        server.check()

        if server.new:
            # New mail on server, might add notification
            if server.name not in self.notifications:
                self.notifications[server.name] = server
            if server.unread > prev_unread:
                self.notify(server)
        else:
            if server.name in self.notifications:
                print('Removing notifications for server %r' % server.name)
                del self.notifications[server.name]

    def notify(self, server):
        """Show a new-mail notofication"""
        print('New mail on server %s' % server.name)
        for mailbox in [mb for mb in server.mailboxes if mb.new]:
            print('    Mailbox: %r' % mailbox)

    def mainloop(self):
        import time
        while True:
            for server in self.servers:
                self.check(server)
            time.sleep(10)

    def run(self):
        try:
            self.mainloop()
        except KeyboardInterrupt:
            for server in self.servers:
                server.imap.logout()
                server.imap.shutdown()

#######################################################################

def main():
    Notifier().run()

if __name__ == '__main__':
    main()

#######################################################################
