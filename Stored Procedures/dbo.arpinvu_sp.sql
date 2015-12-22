SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arpinvu.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[arpinvu_sp] @trx_num	varchar(16), 
			@trx_type	smallint,
			@set_post_flag	smallint,
			@set_print_flag smallint
AS

BEGIN 

	UPDATE	arinpchg 
	SET	printed_flag 	= @set_print_flag, 
		posted_flag 	= @set_post_flag 
	WHERE	trx_ctrl_num 	= @trx_num
	AND 	trx_type 	= @trx_type

END
	


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arpinvu_sp] TO [public]
GO
