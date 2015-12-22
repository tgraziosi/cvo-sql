SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



/*
**
**	              Confidential Information
**	   Limited Distribution of Authorized Persons Only
**	   Created 1991 and Protected as Unpublished Work
**	         Under the U.S. Copyright Act of 1976
**	   Copyright (c) 2000  Epicor Software Corporation
**	              All Rights Reserved
*/

CREATE PROCEDURE [dbo].[gl_taxrep_gen_sp]
@start_date int,
@end_date int,
@report_cur smallint,
@now int,
@user_name varchar(30)


AS
DECLARE
@ret_val int,
@user_id smallint

BEGIN

/* Begin Transaction */
BEGIN TRAN

DELETE 
	 gl_taxrep_dtl

DELETE 
	 gl_taxrep_hdr



EXEC gl_taxrep_ar_gen_sp @start_date, @end_date, @report_cur, @ret_val OUTPUT

/* when error 1 occurs the transaction is rolled back */
IF (@ret_val <> 0)
	BEGIN
		IF (@ret_val = 2) ROLLBACK TRAN
		RETURN
	END
	
EXEC gl_taxrep_ap_gen_sp @start_date, @end_date, @report_cur, @ret_val OUTPUT

/* when error 1 occurs the transaction is rolled back */
IF (@ret_val <> 0)
	BEGIN
		IF (@ret_val = 2) ROLLBACK TRAN
		RETURN
	END
     
/* Get the user ID */
SELECT 
      @user_id = user_id
FROM
	  glusers_vw
WHERE
	  user_name = LTRIM(RTRIM(@user_name ))



IF (EXISTS (SELECT * FROM #gl_taxrep))
INSERT INTO gl_taxrep_hdr
(
	start_date,
	end_date,
	date_generated,
	generated_by,
	report_cur
)
VALUES
(
	@start_date,
	@end_date,
	@now,
	@user_id,
	@report_cur
)

IF (@@error <>0) 
	BEGIN
		ROLLBACK TRAN
		RETURN 
	END

INSERT gl_taxrep_dtl
(
	trx_ctrl_num,
	doc_ctrl_num,
	start_date,
	tax_box_code,
	tax_type_code,
	amt_net,
	amt_tax,
	trx_type
)
SELECT
	trx_ctrl_num,
	doc_ctrl_num,
	@start_date,
	tax_box_code,
	tax_type_code,
	amt_net,
	amt_tax,
	trx_type
FROM
	#gl_taxrep

IF (@@error <>0) 
	BEGIN
		ROLLBACK TRAN
		RETURN 
	END
	

/* Commit Transaction */
COMMIT TRAN

END
GO
GRANT EXECUTE ON  [dbo].[gl_taxrep_gen_sp] TO [public]
GO
