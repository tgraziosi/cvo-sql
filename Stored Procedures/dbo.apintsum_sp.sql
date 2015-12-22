SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apintsum.SPv - e7.2.2 : 1.6
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[apintsum_sp] 

	@is_vend_code varchar(12), @is_pto_code varchar(8), 
	@is_cls_code varchar(8), @is_bch_code varchar(8), 
	@is_date_applied int, @is_proc_key int, 
	@is_user_id int

AS

DECLARE @vend_flag smallint, @cls_flag smallint, @pto_flag smallint,
	@bch_flag smallint, @mast_flag smallint, @date_from int, 
	@date_thru int


SELECT @vend_flag = apsumvnd_flag,
	@cls_flag = apsumcls_flag,
	@pto_flag = apsumpto_flag,
	@bch_flag = apsumbch_flag
FROM apco


SELECT @mast_flag = NULL

SELECT @mast_flag = pay_to_hist_flag
FROM apvend
WHERE vendor_code = @is_vend_code

IF ( @mast_flag IS NULL )
	SELECT @mast_flag = 0



SELECT @date_thru = period_end_date,
	@date_from = period_start_date
FROM glprd
WHERE period_end_date >= @is_date_applied
 AND period_start_date <= @is_date_applied


IF (( @vend_flag = 1 ) AND ( @is_vend_code IS NOT NULL )
AND ( @is_vend_code != SPACE(12))
AND NOT EXISTS( SELECT date_thru FROM apsumvnd
		WHERE vendor_code = @is_vend_code
		 AND @is_date_applied BETWEEN date_from AND date_thru ) )
BEGIN
	INSERT apsumvnd(
		vendor_code, date_from, date_thru,
		num_vouch, num_vouch_paid, num_dm,
		num_adj, num_pyt, num_overdue_pyt,
		num_void, amt_vouch, amt_dm,
		amt_adj, amt_pyt, amt_void, 
		amt_disc_given, amt_disc_taken, amt_disc_lost,
		amt_freight, amt_tax, avg_days_pay,
		avg_days_overdue, last_trx_time )
	VALUES (@is_vend_code, @date_from, @date_thru,
		0, 0, 0, 
		0, 0, 0,
		0, 0, 0, 
		0, 0, 0,
		0, 0, 0, 
		0, 0, 0,
		0, 0 )
END


IF (( @cls_flag = 1 ) AND ( @is_cls_code IS NOT NULL )
AND ( @is_cls_code != SPACE(8))
AND NOT EXISTS( SELECT date_thru FROM apsumcls
		WHERE class_code = @is_cls_code
		 AND @is_date_applied BETWEEN date_from AND date_thru ) )
BEGIN

	INSERT apsumcls(
		class_code, date_from, date_thru,
		num_vouch, num_vouch_paid, num_dm,
		num_adj, num_pyt, num_overdue_pyt,
		num_void, amt_vouch, amt_dm,
		amt_adj, amt_pyt, amt_void, 
		amt_disc_given, amt_disc_taken, amt_disc_lost,
		amt_freight, amt_tax, avg_days_pay,
		avg_days_overdue, last_trx_time )
	VALUES (@is_cls_code, @date_from, @date_thru,
		0, 0, 0, 
		0, 0, 0,
		0, 0, 0, 
		0, 0, 0,
		0, 0, 0, 
		0, 0, 0,
		0, 0 )
END


IF (( @pto_flag = 1 ) AND ( @is_pto_code IS NOT NULL )
AND ( @is_pto_code != SPACE(8)) AND ( @mast_flag = 1 )
AND ( @is_vend_code IS NOT NULL ) AND ( @is_vend_code != SPACE(12) )
AND NOT EXISTS( SELECT date_thru FROM apsumpto
		WHERE vendor_code = @is_vend_code
		 AND pay_to_code = @is_pto_code
		 AND @is_date_applied BETWEEN date_from AND date_thru ) )
BEGIN

	INSERT apsumpto(
		pay_to_code,
		vendor_code, date_from, date_thru,
		num_vouch, num_vouch_paid, num_dm,
		num_adj, num_pyt, num_overdue_pyt,
		num_void, amt_vouch, amt_dm,
		amt_adj, amt_pyt, amt_void, 
		amt_disc_given, amt_disc_taken, amt_disc_lost,
		amt_freight, amt_tax, avg_days_pay,
		avg_days_overdue, last_trx_time )
	VALUES (@is_pto_code,
		@is_vend_code, @date_from, @date_thru,
		0, 0, 0, 
		0, 0, 0,
		0, 0, 0, 
		0, 0, 0,
		0, 0, 0, 
		0, 0, 0,
		0, 0 )
END


IF (( @bch_flag = 1 ) AND ( @is_bch_code IS NOT NULL )
AND ( @is_bch_code != SPACE(8))
AND NOT EXISTS( SELECT date_thru FROM apsumbch
		WHERE branch_code = @is_bch_code
		 AND @is_date_applied BETWEEN date_from AND date_thru ) )
BEGIN

	INSERT apsumbch(
		branch_code, date_from, date_thru,
		num_vouch, num_vouch_paid, num_dm,
		num_adj, num_pyt, num_overdue_pyt,
		num_void, amt_vouch, amt_dm,
		amt_adj, amt_pyt, amt_void, 
		amt_disc_given, amt_disc_taken, amt_disc_lost,
		amt_freight, amt_tax, avg_days_pay,
		avg_days_overdue, last_trx_time )
	VALUES (@is_bch_code, @date_from, @date_thru,
		0, 0, 0, 
		0, 0, 0,
		0, 0, 0, 
		0, 0, 0,
		0, 0, 0, 
		0, 0, 0,
		0, 0 )
END

RETURN 0

GO
GRANT EXECUTE ON  [dbo].[apintsum_sp] TO [public]
GO
