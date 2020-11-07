# $Id:$

MAN=	amount.1

SCRIPT=	amount.sh

realinstall:
	${INSTALL} ${INSTALL_COPY} -o ${BINOWN} -g ${BINGRP} -m ${BINMODE} \
		${.CURDIR}/${SCRIPT} ${DESTDIR}${BINDIR}/amount

.include <bsd.prog.mk>
