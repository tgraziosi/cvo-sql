SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\appobnum.SPv - e7.2.2 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                





CREATE PROCEDURE [dbo].[appobnum_sp]
	@batch_flag smallint OUTPUT, 	
	@batch_ctrl_num char(16) OUTPUT 	
as
declare
	@ap_po_flag 		smallint	

	SELECT @batch_flag = -1
	
	
	SELECT @ap_po_flag = po_flag 	
	FROM apco

	IF (@ap_po_flag = 0) OR (@@ROWCOUNT = 0) 		
		RETURN

	EXEC apbatnum_sp @batch_flag OUTPUT, @batch_ctrl_num OUTPUT



GO
GRANT EXECUTE ON  [dbo].[appobnum_sp] TO [public]
GO
