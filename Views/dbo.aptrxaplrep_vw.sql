SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



/*
**  aptrxapl.vw
**
**	View for vouchers that are not paid in full and
**	not on payment hold.
**
**
**
**  AUTHOR:	Cbalderas	10/18/2002
**
**	              Confidential Information
**	   Limited Distribution of Authorized Persons Only
**	   Created 1992 and Protected as Unpublished Work
**	         Under the U.S. Copyright Act of 1976
**	Copyright (c) 1992  Advanced Business Microsystems, Inc.
**	                 All Rights Reserved
*/
CREATE VIEW [dbo].[aptrxaplrep_vw]
	AS SELECT	*
	FROM 		apvohdr





GO
GRANT REFERENCES ON  [dbo].[aptrxaplrep_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[aptrxaplrep_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[aptrxaplrep_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[aptrxaplrep_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptrxaplrep_vw] TO [public]
GO
