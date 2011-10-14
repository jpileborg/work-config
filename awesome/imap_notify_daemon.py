#!/usr/bin/env /usr/bin/python
#######################################################################
# File: imap-notify-daemon.py                                         #
#                                                                     #
# Copyright (C) 2011 by Joachim Pileborg <arrow@pileborg.org>         #
# All rights reserved.                                                #
#                                                                     #
# This file is free to distribute in source-form only, or modify, but #
# only if this file header contains the above copyright notice.       #
#######################################################################

"""
The purpose of this application is to run in the background, checking
IMAP mail accounts, and displaying a notification icon when new mail
has arrived.

This application checks for new mail in all subscribed folders on all
configured accounts.
"""

#######################################################################

from imap_notify_accounts import accounts as imap_accounts

#######################################################################

#######################################################################
