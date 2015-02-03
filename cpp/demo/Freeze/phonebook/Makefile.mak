# **********************************************************************
#
# Copyright (c) 2003-2015 ZeroC, Inc. All rights reserved.
#
# This copy of Ice is licensed to you under the terms described in the
# ICE_LICENSE file included in this distribution.
#
# **********************************************************************

top_srcdir	= ..\..\..

!if exist ($(top_srcdir)\..\.gitignore)
MAXWARN         = yes
!endif

CLIENT		= client.exe
SERVER		= server.exe
COLLOCATED	= collocated.exe

TARGETS		= $(CLIENT) $(SERVER) $(COLLOCATED)

SLICE_OBJS	= .\PhoneBook.obj

COBJS		= $(SLICE_OBJS) \
		  .\Client.obj \
		  .\Grammar.obj \
		  .\Parser.obj \
		  .\RunParser.obj \
		  .\Scanner.obj

SOBJS		= $(SLICE_OBJS) \
		  .\NameIndex.obj \
		  .\ContactFactory.obj \
		  .\PhoneBookI.obj \
		  .\Server.obj

COLOBJS		= $(SLICE_OBJS) \
		  .\NameIndex.obj \
		  .\Collocated.obj \
		  .\ContactFactory.obj \
		  .\Grammar.obj \
		  .\Parser.obj \
		  .\PhoneBookI.obj \
		  .\RunParser.obj \
		  .\Scanner.obj

OBJS		= $(COBJS) \
		  $(SOBJS) \
		  $(COLOBJS)

all:: NameIndex.cpp NameIndex.h

!include $(top_srcdir)/config/Make.rules.mak

CPPFLAGS	= -I. $(CPPFLAGS) -DWIN32_LEAN_AND_MEAN

!if "$(GENERATE_PDB)" == "yes"
CPDBFLAGS        = /pdb:$(CLIENT:.exe=.pdb)
SPDBFLAGS        = /pdb:$(SERVER:.exe=.pdb)
COPDBFLAGS       = /pdb:$(COLLOCATED:.exe=.pdb)
!endif

$(CLIENT): $(COBJS)
	$(LINK) $(LD_EXEFLAGS) $(CPDBFLAGS) $(SETARGV) $(COBJS) $(PREOUT)$@ $(PRELIBS)$(LIBS)
	@if exist $@.manifest echo ^ ^ ^ Embedding manifest using $(MT) && \
	    $(MT) -nologo -manifest $@.manifest -outputresource:$@;#1 && del /q $@.manifest

$(SERVER): $(SOBJS)
	$(LINK) $(LD_EXEFLAGS) $(SPDBFLAGS) $(SETARGV) $(SOBJS) $(PREOUT)$@ $(PRELIBS)$(LIBS) 
	@if exist $@.manifest echo ^ ^ ^ Embedding manifest using $(MT) && \
	    $(MT) -nologo -manifest $@.manifest -outputresource:$@;#1 && del /q $@.manifest

$(COLLOCATED): $(COLOBJS)
	$(LINK) $(LD_EXEFLAGS) $(COPDBFLAGS) $(SETARGV) $(COLOBJS) $(PREOUT)$@ $(PRELIBS)$(LIBS) 
	@if exist $@.manifest echo ^ ^ ^ Embedding manifest using $(MT) && \
	    $(MT) -nologo -manifest $@.manifest -outputresource:$@;#1 && del /q $@.manifest

NameIndex.h NameIndex.cpp: PhoneBook.ice "$(SLICE2FREEZE)" "$(SLICEPARSERLIB)"
	del /q NameIndex.h NameIndex.cpp
	"$(SLICE2FREEZE)" -I. $(ICECPPFLAGS) --index NameIndex,Demo::Contact,name,case-insensitive NameIndex PhoneBook.ice

Scanner.cpp : Scanner.l
	flex Scanner.l
	del /q $@
	echo #include "IceUtil/ScannerConfig.h" >> Scanner.cpp
	type lex.yy.c >> Scanner.cpp
	del /q lex.yy.c

Grammar.cpp Grammar.h: Grammar.y
	del /q Grammar.h Grammar.cpp
	bison -dvt Grammar.y
	move Grammar.tab.c Grammar.cpp
	move Grammar.tab.h Grammar.h
	del /q Grammar.output

clean::
	del /q PhoneBook.cpp PhoneBook.h

clean::
	-del /q NameIndex.h NameIndex.cpp
	-if exist db\__Freeze rmdir /q /s db\__Freeze
	-for %f in (db\*) do if not %f == db\.gitignore del /q %f
