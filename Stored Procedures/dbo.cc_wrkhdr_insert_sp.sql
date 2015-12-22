SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[cc_wrkhdr_insert_sp]	@workload_code varchar(8),
																			@workload_desc varchar(65),
																			@sort_order smallint = 0
	AS

		DELETE FROM ccwrkhdr WHERE workload_code = @workload_code
		DELETE FROM ccwrkdet WHERE workload_code = @workload_code
		
		INSERT ccwrkhdr 
		SELECT @workload_code,@workload_desc, GETDATE(), @sort_order
    
GO
GRANT EXECUTE ON  [dbo].[cc_wrkhdr_insert_sp] TO [public]
GO
