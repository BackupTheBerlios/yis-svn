#
# Copyright (C) 2006 Tobias Gerschner <tobias@lists.yoper.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

VERSION = 0.3.2

DOC = \
	README		\
	TODO

COMMON = \
	add-network-interfaces.sh	\
	chroot_setup.sh			\
	copy-files.sh			\
	copy-settings.sh		\
	detect-valid-partitions.sh	\
	discinfo.sh			\
	firstboot.sh			\
	checkmd5sum.sh			\
	install-grub.sh			\
	install-lilo.sh			\
	install-packages.sh		\
	lossless-repartitioning.sh	\
	lossless-resize.sh		\
	make-iso.sh			\
	mkinitrd.sh			\
	parted-info.sh			\
	partitioning.sh			\
	shrink-partition.sh		\
	start-yis.sh			\
	write-bootloader-config.sh

CONFIG = \
	grub.conf.template		\
	lilo.conf.template		\
	inittab.cd			\
	settings

EXECS = \
	yoperinstall

INSTALL = /usr/bin/install -c
INSTALL_EXEC = ${INSTALL} -m 0755
INSTALL_DATA = ${INSTALL} -m 644
INSTALL_SCRIPT = ${INSTALL_PROGRAM}

PWD = $(shell pwd)

YPREFIX = /usr/lib/yis
COMMON_DIR = $(YPREFIX)/common
CLI_DIR = $(YPREFIX)/cli

SYSCONFDIR = /etc
SBINDIR	= /usr/sbin

.PHONY: 	install	
.SILENT: 	check-dstdir

check-dstdir:

ifndef DESTDIR
	echo "" 
	echo "You should not install this package into a running system, yet" ; \
	echo "Use DESTDIR to define a location to install the files, to." ; \
	echo "" 
	exit 1
endif

install-files:
	@echo "Creating basic File Structure in ${DESTDIR}" 
	mkdir -p $(DESTDIR)/{$(COMMON_DIR),$(CLI_DIR),$(SBINDIR),$(SYSCONFDIR)/yis/{packages,rc.d,rcS.d}}

	$(INSTALL_EXEC) $(COMMON) $(DESTDIR)$(COMMON_DIR)
	$(INSTALL_DATA) $(CONFIG) $(DESTDIR)$(SYSCONFDIR)/yis

	#install the user-visible hook
	$(INSTALL_EXEC) yoperinstall $(DESTDIR)$(SBINDIR)

	$(INSTALL_EXEC) rc $(DESTDIR)$(SYSCONFDIR)/yis/rc.d

	$(INSTALL_EXEC) cli.sh $(DESTDIR)$(CLI_DIR)

create-spec:

	@echo "Modifying SPEC File" 
	sed -e  "s|#SYSCONFDIR#|${SYSCONFDIR}|g;s|#SBINDIR#|${SBINDIR}|g;s|#COMMON_DIR#|${COMMON_DIR}|g;s|#VERSION#|${VERSION}|g;s|#CLI_DIR#|${CLI_DIR}|g" < yis-cli.spec.in > yis-cli.spec
	
install:  check-dstdir install-files

spec:	  create-spec

