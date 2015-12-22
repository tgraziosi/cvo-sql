SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\perf.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROCEDURE [dbo].[perf_sp]
	@batch_ctrl_num	varchar( 16 ),
	@procedure_name	varchar( 32 ),
	@line_nbr	smallint,
	@comment	varchar( 80 ),
	@time_last	datetime OUTPUT

AS

DECLARE
	@time_now	datetime,
	@time_elapsed	int

SELECT	@time_now = GETDATE()

SELECT	@time_elapsed = DATEDIFF( ms, @time_last, @time_now )

INSERT	perf ( process_code,
	 procedure_name,
	 line_nbr,
	 time_event,
	 time_elapsed,
	 comment )

VALUES	( @batch_ctrl_num + "-" + ltrim( rtrim( STR( @@spid, 10 ))),
	 @procedure_name,
	 @line_nbr,
	 @time_now,
	 @time_elapsed,
	 @comment )

SELECT @time_last = GETDATE()

RETURN


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[perf_sp] TO [public]
GO
