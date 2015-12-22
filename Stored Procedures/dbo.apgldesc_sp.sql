SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apgldesc.SPv - e7.2.2 : 1.8
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROCEDURE [dbo].[apgldesc_sp]
	@trx_ctrl_num	varchar(16),
	@vendor_code	varchar(12),
	@seq_id		int,
	@line_desc	varchar(41) OUTPUT

AS DECLARE
	@gl_def_flag	smallint


SELECT 	@line_desc = ''


SELECT	@gl_def_flag = gl_desc_def
FROM	apco


IF	@gl_def_flag = 1 AND @vendor_code IS NOT NULL
BEGIN
 if (( SELECT one_time_vend_flag FROM apinpchg
 WHERE trx_ctrl_num = @trx_ctrl_num ) = 1)
 BEGIN
		SELECT	@line_desc = pay_to_addr1	
 FROM apinpchg
 	WHERE trx_ctrl_num = @trx_ctrl_num
 END
 ELSE
 BEGIN
		SELECT	@line_desc = vendor_name	
		FROM	apvend
		WHERE	vendor_code = @vendor_code
 END
END


IF 	@gl_def_flag = 2 AND @vendor_code IS NOT NULL
	SELECT	@line_desc = @vendor_code+'/'+@trx_ctrl_num


IF 	( @gl_def_flag = 3 )
BEGIN
	IF @seq_id > 0
		SELECT	@line_desc = @vendor_code +'/'+item_code
		FROM	apinpcdt
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND	sequence_id = @seq_id
	ELSE
		SELECT	@line_desc = @vendor_code
END


IF 	( @gl_def_flag = 4 )
BEGIN
	IF @seq_id > 0
		SELECT	@line_desc = @vendor_code+'/'+line_desc
		FROM	apinpcdt
		WHERE	trx_ctrl_num = @trx_ctrl_num
		AND	sequence_id = @seq_id
	ELSE
		SELECT	@line_desc = @vendor_code
END

GO
GRANT EXECUTE ON  [dbo].[apgldesc_sp] TO [public]
GO
