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

VERSION = 0.3.4

DOC = \
	README		\
	TODO

COMMON = \
	add-network-interfaces.sh	\
	copy-files.sh			\
	copy-settings.sh		\
	discinfo.sh			\
	firstboot.sh			\
	checkmd5sum.sh			\
	install-flash.sh		\
	install-grub.sh			\
	install-lilo.sh			\
	install-packages.sh		\
	make-iso.sh			\
	mkinitrd.sh			\
	reset-smart-channels.sh		\
	start-yis.sh			\
	write-bootloader-config.sh

FIRSTBOOT = \
	S00_removablemedia \
	S00_services \
	S01_localization \
	S10_dhclient \
	S20_ssh \
	S50_usersetup \
	S60_oss \
	S60_reset_package_channels 	\
	S61_install_flash
	
CONFIG = \
	grub.conf.template		\
	lilo.conf.template		\
	inittab.cd			\
	settings			\
	packages.info

EXECS = \
	yoperinstall

LIVECD = \
	start-live-cd.sh	

COMMONCD_INIT = \
	S00_disable_prelink \
	S00_disable_services \
	S10_dhclient \
	S60_oss

LIVECD_INIT = \
	S00_disable_service_in_livecd 	\
	S10_recheck_network		\
	S60_reset_package_channels 	\
	S60_oss			 	\
	S61_install_flash

INSTALL = /usr/bin/install -c
INSTALL_EXEC = ${INSTALL} -m 0755
INSTALL_DATA = ${INSTALL} -m 644
INSTALL_SCRIPT = ${INSTALL_PROGRAM}

PWD = $(shell pwd)

YPREFIX = /usr/lib/yis
COMMON_DIR = $(YPREFIX)/common
LIVECD_DIR = $(YPREFIX)/livecd
CLI_DIR = $(YPREFIX)/cli

SYSCONFDIR = /etc
SBINDIR	= /usr/sbin

LIVECD_INIT_DIR = $(SYSCONFDIR)/yis/livemode.d

COMMONCD_INIT_DIR = $(SYSCONFDIR)/yis/rcS.d

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
	mkdir -p $(DESTDIR)/YIS/{$(COMMON_DIR),$(LIVECD_DIR),$(CLI_DIR),$(SBINDIR),$(SYSCONFDIR)/yis/{packages,rc.d,rcS.d,firstboot.d}}
	
	mkdir -p $(DESTDIR)/YIS/$(LIVECD_INIT_DIR)
	mkdir -p $(DESTDIR)/YIS/$(COMMONCD_INIT_DIR)

	$(INSTALL_EXEC) $(COMMON) $(DESTDIR)/YIS$(COMMON_DIR)
	$(INSTALL_DATA) $(CONFIG) $(DESTDIR)/YIS$(SYSCONFDIR)/yis

	#install the user-visible hook
	$(INSTALL_EXEC) yoperinstall $(DESTDIR)/YIS$(SBINDIR)

	$(INSTALL_EXEC) rc $(DESTDIR)/YIS$(SYSCONFDIR)/yis/rc.d

	$(INSTALL_EXEC) cli.sh $(DESTDIR)/YIS$(CLI_DIR)

	$(INSTALL_EXEC) $(LIVECD) $(DESTDIR)/YIS$(LIVECD_DIR)

	$(INSTALL_EXEC) $(COMMONCD_INIT) $(DESTDIR)/YIS$(COMMONCD_INIT_DIR)

	$(INSTALL_EXEC) $(FIRSTBOOT) $(DESTDIR)//YIS$(SYSCONFDIR)/yis/firstboot.d

	$(INSTALL_EXEC) $(LIVECD_INIT) $(DESTDIR)/YIS$(LIVECD_INIT_DIR)

create-spec:

	@echo "Modifying SPEC File" 
	sed -e  "s|#SYSCONFDIR#|${SYSCONFDIR}|g;s|#SBINDIR#|${SBINDIR}|g;s|#COMMON_DIR#|${COMMON_DIR}|g;s|#VERSION#|${VERSION}|g;s|#CLI_DIR#|${CLI_DIR}|g" < yis-cli.spec.in > yis-cli.spec
	
install:  check-dstdir install-files

spec:	  create-spec

