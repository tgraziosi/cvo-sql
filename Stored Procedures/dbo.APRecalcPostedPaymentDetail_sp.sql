SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\aprpd.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[APRecalcPostedPaymentDetail_sp]
AS
BEGIN
DECLARE
	@old_trx_num 		varchar(16),
	@det_trx_ctrl_num	varchar(16),
	@sequence_id 		int,
	@fetch_status 		smallint


CREATE TABLE #appydet_new
(
	trx_ctrl_num varchar(16),
	sequence_id int,
	apply_to_num varchar(16),
	date_aging				int,
	date_applied			int,
	amt_applied float,
	amt_disc_taken float,
	line_desc varchar(40),
	void_flag smallint,
	vo_amt_applied			float,
	vo_amt_disc_taken		float,
	gain_home				float,
	gain_oper				float,
	flag smallint
)

CREATE CLUSTERED INDEX #appydet_new_ind_0 on #appydet_new (trx_ctrl_num)

CREATE TABLE #appyhdr_tmp
(
	trx_ctrl_num varchar(16),
	doc_ctrl_num varchar(16),
	cash_acct_code varchar(32)

)


INSERT	#appyhdr_tmp
SELECT	MIN(trx_ctrl_num),
	doc_ctrl_num,
	cash_acct_code
FROM	appyhdr
WHERE	payment_type in (1,3)
GROUP BY
	doc_ctrl_num, cash_acct_code

INSERT #appydet_new
(
	trx_ctrl_num,
	sequence_id,
	apply_to_num,
	date_aging,
	date_applied,
	amt_applied,
	amt_disc_taken,
	line_desc,
	void_flag,
	vo_amt_applied,
	vo_amt_disc_taken,
	gain_home,
	gain_oper,
	flag
)
SELECT
	c.trx_ctrl_num,
	0,
	b.apply_to_num,
	b.date_aging,
	b.date_applied,
	b.amt_applied,
	b.amt_disc_taken,
	b.line_desc,
	b.void_flag,
	b.vo_amt_applied,
	b.vo_amt_disc_taken,
	b.gain_home,
	b.gain_oper,
	0
FROM	appyhdr a, appydet b, #appyhdr_tmp c
WHERE	a.trx_ctrl_num = b.trx_ctrl_num
AND	a.doc_ctrl_num = c.doc_ctrl_num
AND	a.cash_acct_code = c.cash_acct_code
ORDER BY a.doc_ctrl_num



DECLARE trxcursor CURSOR FOR
SELECT DISTINCT trx_ctrl_num FROM #appydet_new WHERE sequence_id = 0 ORDER BY trx_ctrl_num



OPEN trxcursor

FETCH NEXT FROM trxcursor INTO @det_trx_ctrl_num

SELECT @fetch_status = @@FETCH_STATUS

WHILE ( @fetch_status = 0 )
BEGIN
	SELECT @sequence_id = 0

	UPDATE #appydet_new
	SET	sequence_id = @sequence_id,
		@sequence_id = @sequence_id + 1
	WHERE trx_ctrl_num = @det_trx_ctrl_num

	FETCH NEXT FROM trxcursor INTO @det_trx_ctrl_num

	SELECT @fetch_status = @@FETCH_STATUS
END

CLOSE trxcursor
DEALLOCATE trxcursor

SET ROWCOUNT 0


DELETE 	appydet

WHILE (1=1)
BEGIN

SET ROWCOUNT 10000

UPDATE #appydet_new
SET flag = 1

SET ROWCOUNT 0

INSERT 	appydet
(
	trx_ctrl_num,
	sequence_id,
	apply_to_num,
	date_aging,
	date_applied,
	amt_applied,
	amt_disc_taken,
	line_desc,
	void_flag,
	vo_amt_applied,
	vo_amt_disc_taken,
	gain_home,
	gain_oper
)
SELECT
	trx_ctrl_num,
	sequence_id,
	apply_to_num,
	date_aging,
	date_applied,
	amt_applied,
	amt_disc_taken,
	line_desc,
	void_flag,
	vo_amt_applied,
	vo_amt_disc_taken,
	gain_home,
	gain_oper

FROM	#appydet_new
WHERE	flag = 1

IF @@rowcount = 0 BREAK

DELETE #appydet_new
WHERE flag = 1

CHECKPOINT

END
	 
DROP TABLE #appyhdr_tmp
DROP TABLE #appydet_new

END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[APRecalcPostedPaymentDetail_sp] TO [public]
GO
