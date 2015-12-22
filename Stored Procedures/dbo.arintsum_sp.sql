SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arintsum.SPv - e7.2.2 : 1.9
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[arintsum_sp]	
	@is_cus_code char(10),	@is_prc_code char(10),	@is_shp_code char(10),
	@is_slp_code char(10),	@is_ter_code char(10),	@is_date_applied int,
	@is_proc_key int,	@is_user_id int
AS

DECLARE	@cus_flag smallint,	@prc_flag smallint,	@shp_flag smallint,
	@slp_flag smallint,	@ter_flag smallint,	@mast_flag smallint,
	@date_from int,		@date_thru int,
	@err_mess char(80),	@err_mess_date char(12), @E_INV_DATE_APPLIED int,
	@E_ARINTSUM_FAILED int,	@error_occured smallint



SELECT @error_occured = 0


SELECT	@cus_flag = arsumcus_flag, @prc_flag = arsumprc_flag, 
	@shp_flag = arsumshp_flag, @slp_flag = arsumslp_flag, 
	@ter_flag = arsumter_flag
FROM	arco
IF @@error != 0
	SELECT @error_occured = 1


SELECT	@mast_flag = NULL

SELECT	@mast_flag = ship_to_history
FROM	arcust
WHERE	customer_code = @is_cus_code
IF @@error != 0
	SELECT @error_occured = 1

IF ( @mast_flag IS NULL )
	SELECT	@mast_flag = 0



SELECT @date_thru = NULL
SELECT @date_from = NULL

SELECT	@date_thru = period_end_date,
	@date_from = period_start_date
FROM 	glprd
WHERE	period_end_date >= @is_date_applied
 AND	period_start_date <= @is_date_applied

IF ( @date_thru IS NULL ) OR ( @date_from IS NULL )
	RETURN 2


IF (( @cus_flag = 1 ) AND ( @is_cus_code IS NOT NULL ) AND ( @is_cus_code != SPACE(10))
AND NOT EXISTS( SELECT date_thru FROM arsumcus 
		WHERE customer_code = @is_cus_code
		 AND @is_date_applied BETWEEN date_from AND date_thru ) )
BEGIN

	INSERT	arsumcus(
		customer_code,	date_from,	date_thru,
		num_inv,	num_inv_paid,	num_cm,
		num_adj,	num_wr_off,	num_pyt,
		num_overdue_pyt,num_nsf,	num_fin_chg,
		num_late_chg,	amt_inv,	amt_cm,
		amt_adj,	amt_wr_off,	amt_pyt,
		amt_nsf,	amt_fin_chg,	amt_late_chg,
		amt_profit,	prc_profit,	amt_comm,
		amt_disc_given,	amt_disc_taken,	amt_disc_lost,
		amt_freight,	amt_tax,	avg_days_pay,
		avg_days_overdue, last_trx_time,
	amt_inv_oper,
	amt_cm_oper,
	amt_adj_oper,
	amt_wr_off_oper,
	amt_pyt_oper,
	amt_nsf_oper,
	amt_fin_chg_oper,
	amt_late_chg_oper,
	amt_disc_g_oper,	
	amt_disc_t_oper,
	amt_freight_oper,
	amt_tax_oper	
		 )
	VALUES	(@is_cus_code,	@date_from,	@date_thru,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
 		0,		0,		0,		
		0,		0,
		0,0,0,0,0,0,0,0,0,0,0,0 )
	IF @@error != 0
		SELECT @error_occured = 1
END 


IF (( @prc_flag = 1 ) AND ( @is_prc_code IS NOT NULL ) AND ( @is_prc_code != SPACE(10))
AND NOT EXISTS( SELECT date_thru FROM arsumprc
		WHERE price_code = @is_prc_code
		 AND @is_date_applied BETWEEN date_from AND date_thru ) )
BEGIN

	INSERT	arsumprc(
		price_code,	date_from,	date_thru,
		num_inv,	num_inv_paid,	num_cm,
		num_adj,	num_wr_off,	num_pyt,
		num_overdue_pyt,num_nsf,	num_fin_chg,
		num_late_chg,	amt_inv,	amt_cm,
		amt_adj,	amt_wr_off,	amt_pyt,
		amt_nsf,	amt_fin_chg,	amt_late_chg,
		amt_profit,	prc_profit,	amt_comm,
		amt_disc_given,	amt_disc_taken,	amt_disc_lost,
		amt_freight,	amt_tax,	avg_days_pay,
		avg_days_overdue, last_trx_time,
	amt_inv_oper,
	amt_cm_oper,
	amt_adj_oper,
	amt_wr_off_oper,
	amt_pyt_oper,
	amt_nsf_oper,
	amt_fin_chg_oper,
	amt_late_chg_oper,
	amt_disc_g_oper,	
	amt_disc_t_oper,
	amt_freight_oper,
	amt_tax_oper	
		 )
	VALUES	(@is_prc_code,	@date_from,	@date_thru,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
 		0,		0,		0,		
		0,		0,
		0,0,0,0,0,0,0,0,0,0,0,0 )
	IF @@error != 0
		SELECT @error_occured = 1

END 


IF (( @shp_flag = 1 ) AND ( @is_shp_code IS NOT NULL ) 
AND ( @is_shp_code != SPACE(10)) AND ( @mast_flag = 1 ) 
AND ( @is_cus_code IS NOT NULL ) AND ( @is_cus_code != SPACE(10) )
AND NOT EXISTS( SELECT	date_thru FROM arsumshp
		WHERE	customer_code = @is_cus_code
		 AND	ship_to_code = @is_shp_code
		 AND	@is_date_applied BETWEEN date_from AND date_thru ) )
BEGIN

	INSERT	arsumshp(
		ship_to_code,
		customer_code,	date_from,	date_thru,
		num_inv,	num_inv_paid,	num_cm,
		num_adj,	num_wr_off,	num_pyt,
		num_overdue_pyt,num_nsf,	num_fin_chg,
		num_late_chg,	amt_inv,	amt_cm,
		amt_adj,	amt_wr_off,	amt_pyt,
		amt_nsf,	amt_fin_chg,	amt_late_chg,
		amt_profit,	prc_profit,	amt_comm,
		amt_disc_given,	amt_disc_taken,	amt_disc_lost,
		amt_freight,	amt_tax,	avg_days_pay,
		avg_days_overdue, last_trx_time,
	amt_inv_oper,
	amt_cm_oper,
	amt_adj_oper,
	amt_wr_off_oper,
	amt_pyt_oper,
	amt_nsf_oper,
	amt_fin_chg_oper,
	amt_late_chg_oper,
	amt_disc_g_oper,	
	amt_disc_t_oper,
	amt_freight_oper,
	amt_tax_oper	
		 )
	VALUES	(@is_shp_code,
		@is_cus_code,	@date_from,	@date_thru,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
 		0,		0,		0,		
		0,		0,
		0,0,0,0,0,0,0,0,0,0,0,0 )
	IF @@error != 0
		SELECT @error_occured = 1

END 


IF (( @slp_flag = 1 ) AND ( @is_slp_code IS NOT NULL ) 
AND ( @is_slp_code != SPACE(10))
AND NOT EXISTS( SELECT date_thru FROM arsumslp
		WHERE salesperson_code = @is_slp_code
		 AND @is_date_applied BETWEEN date_from AND date_thru ) )
BEGIN

	INSERT	arsumslp(
		salesperson_code, date_from,	date_thru,
		num_inv,	num_inv_paid,	num_cm,
		num_adj,	num_wr_off,	num_pyt,
		num_overdue_pyt,num_nsf,	num_fin_chg,
		num_late_chg,	amt_inv,	amt_cm,
		amt_adj,	amt_wr_off,	amt_pyt,
		amt_nsf,	amt_fin_chg,	amt_late_chg,
		amt_profit,	prc_profit,	amt_comm,
		amt_disc_given,	amt_disc_taken,	amt_disc_lost,
		amt_freight,	amt_tax,	avg_days_pay,
		avg_days_overdue, last_trx_time,
	amt_inv_oper,
	amt_cm_oper,
	amt_adj_oper,
	amt_wr_off_oper,
	amt_pyt_oper,
	amt_nsf_oper,
	amt_fin_chg_oper,
	amt_late_chg_oper,
	amt_disc_g_oper,	
	amt_disc_t_oper,
	amt_freight_oper,
	amt_tax_oper	
		 )
	VALUES	(@is_slp_code,	@date_from,	@date_thru,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
 		0,		0,		0,		
		0,		0,
		0,0,0,0,0,0,0,0,0,0,0,0 )
	IF @@error != 0
		SELECT @error_occured = 1

END 


IF (( @ter_flag = 1 ) AND ( @is_ter_code IS NOT NULL ) 
AND ( @is_ter_code != SPACE(10))
AND NOT EXISTS( SELECT date_thru FROM arsumter
		WHERE territory_code = @is_ter_code
		 AND @is_date_applied BETWEEN date_from AND date_thru ) )
BEGIN

	INSERT	arsumter(
		territory_code, date_from,	date_thru,
		num_inv,	num_inv_paid,	num_cm,
		num_adj,	num_wr_off,	num_pyt,
		num_overdue_pyt,num_nsf,	num_fin_chg,
		num_late_chg,	amt_inv,	amt_cm,
		amt_adj,	amt_wr_off,	amt_pyt,
		amt_nsf,	amt_fin_chg,	amt_late_chg,
		amt_profit,	prc_profit,	amt_comm,
		amt_disc_given,	amt_disc_taken,	amt_disc_lost,
		amt_freight,	amt_tax,	avg_days_pay,
		avg_days_overdue, last_trx_time,
	amt_inv_oper,
	amt_cm_oper,
	amt_adj_oper,
	amt_wr_off_oper,
	amt_pyt_oper,
	amt_nsf_oper,
	amt_fin_chg_oper,
	amt_late_chg_oper,
	amt_disc_g_oper,	
	amt_disc_t_oper,
	amt_freight_oper,
	amt_tax_oper	
		 )
	VALUES	(@is_ter_code,	@date_from,	@date_thru,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
		0,		0,		0,		
		0,		0,		0,
 		0,		0,		0,		
		0,		0,
		0,0,0,0,0,0,0,0,0,0,0,0 )
	IF @@error != 0
		SELECT @error_occured = 1

END 

IF @error_occured = 1
	RETURN 1
ELSE
	RETURN 0



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arintsum_sp] TO [public]
GO
