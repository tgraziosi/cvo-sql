SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                


CREATE PROCEDURE [dbo].[gltc_updfreightdtl_sp]
	@tablename  varchar(255),
	@trx_ctrl_num varchar(16),
	@trx_type smallint,
	@debug_level  smallint = 0

WITH RECOMPILE
AS
declare @tmp_amt_final_tax float

if @tablename = '#apinptax3500' 
begin
	IF OBJECT_ID('tempdb..#apinptax3500') IS NOT NULL 
		AND OBJECT_ID('tempdb..#apinptaxdtl3500') IS NOT NULL 
	begin
		select @tmp_amt_final_tax = amt_final_tax from #apinptax3500 where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
		and tax_type_code IN (
			select tax_type_code 
			from #apinptaxdtl3500 
			where #apinptax3500.trx_ctrl_num = #apinptaxdtl3500.trx_ctrl_num 
			and #apinptax3500.trx_type = #apinptaxdtl3500.trx_type
			and #apinptaxdtl3500.detail_sequence_id = 0
			)

		UPDATE #apinptaxdtl3500 SET amt_final_tax = @tmp_amt_final_tax
		WHERE trx_ctrl_num = @trx_ctrl_num and detail_sequence_id = 0

	end
end

if @tablename = '#apinptax3560' 
begin
	IF OBJECT_ID('tempdb..#apinptax3560') IS NOT NULL 
		AND OBJECT_ID('tempdb..#apinptaxdtl3560') IS NOT NULL 
	begin
		select @tmp_amt_final_tax = amt_final_tax from #apinptax3560 where trx_ctrl_num = @trx_ctrl_num and trx_type = @trx_type
		and tax_type_code IN (
			select tax_type_code 
			from #apinptaxdtl3560 
			where #apinptax3560.trx_ctrl_num = #apinptaxdtl3560.trx_ctrl_num 
			and #apinptax3560.trx_type = #apinptaxdtl3560.trx_type
			and #apinptaxdtl3560.detail_sequence_id = 0
			)

		UPDATE #apinptaxdtl3560 SET amt_final_tax = @tmp_amt_final_tax
		WHERE trx_ctrl_num = @trx_ctrl_num and detail_sequence_id = 0

	end
end
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[gltc_updfreightdtl_sp] TO [public]
GO
